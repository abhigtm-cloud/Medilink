import { CandidateWithLocation } from "./candidates";

/** Assumed average speed when the Distance Matrix API isn't configured or
 * fails — a straight-line-distance fallback so scoring still degrades
 * gracefully instead of erroring out. See architecture doc §24 (Distance
 * Matrix API billing is a flagged open item). */
const FALLBACK_AVERAGE_SPEED_KMH = 40;

function fallbackEtaMinutes(distanceKm: number): number {
  return (distanceKm / FALLBACK_AVERAGE_SPEED_KMH) * 60;
}

/**
 * Batches all candidates into one Google Distance Matrix API call. Falls
 * back to a distance/speed estimate per candidate if `GOOGLE_MAPS_API_KEY`
 * isn't set, or if the API call fails for any reason — the SOS flow must
 * never be blocked by a missing Maps billing account.
 */
export async function enrichWithEta(
  lat: number,
  lng: number,
  candidates: CandidateWithLocation[]
): Promise<CandidateWithLocation[]> {
  if (candidates.length === 0) return candidates;

  const apiKey = process.env.GOOGLE_MAPS_API_KEY;
  if (!apiKey) {
    return candidates.map((c) => ({ ...c, etaMinutes: fallbackEtaMinutes(c.distanceKm) }));
  }

  try {
    const destinations = candidates
      .map((c) => `${c.location.latitude},${c.location.longitude}`)
      .join("|");

    const url =
      `https://maps.googleapis.com/maps/api/distancematrix/json` +
      `?origins=${lat},${lng}&destinations=${destinations}&key=${apiKey}`;

    const response = await fetch(url);
    const json = (await response.json()) as {
      rows?: { elements: { duration?: { value: number }; status: string }[] }[];
    };
    const elements = json.rows?.[0]?.elements ?? [];

    return candidates.map((c, i) => {
      const element = elements[i];
      if (element?.status === "OK" && element.duration) {
        return { ...c, etaMinutes: element.duration.value / 60 };
      }
      return { ...c, etaMinutes: fallbackEtaMinutes(c.distanceKm) };
    });
  } catch {
    return candidates.map((c) => ({ ...c, etaMinutes: fallbackEtaMinutes(c.distanceKm) }));
  }
}
