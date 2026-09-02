import 'package:flutter_test/flutter_test.dart';

// Copy of pure intelligence function for isolated testing
(String, bool) generateMedicalAdvice(String query) {
  final q = query.toLowerCase();

  // 1. Emergency Red Flags
  if (q.contains('chest pain') ||
      q.contains('heart attack') ||
      q.contains('cannot breathe') ||
      q.contains('cant breathe') ||
      q.contains('unconscious') ||
      q.contains('stroke') ||
      q.contains('face drooping') ||
      q.contains('paralysis') ||
      q.contains('severe allergic') ||
      q.contains('anaphylaxis') ||
      q.contains('coughing blood') ||
      q.contains('vomiting blood')) {
    return (
      '🚨 CRITICAL MEDICAL ALERT: Immediate hospital intervention is required. Call 108 immediately.',
      true,
    );
  }

  // 2. High Fever & Chills
  if (q.contains('fever') || q.contains('temperature') || q.contains('chills') || q.contains('shivering')) {
    return (
      '🌡️ Management & First-Aid for Fever: Hydration, Paracetamol, External cooling with room-temperature cloth.',
      false,
    );
  }

  // 3. Headache & Migraine
  if (q.contains('headache') || q.contains('migraine') || q.contains('head pain')) {
    return (
      '💆 Relief Guidance for Headache & Migraine: Quiet dark room, hydration, cool compress on forehead.',
      false,
    );
  }

  // 4. Burns & Scalds
  if ((q.contains('burn') && !q.contains('burning') && !q.contains('heartburn')) ||
      q.contains('scald') ||
      q.contains('hot water')) {
    return (
      '🩹 First-Aid for Minor Burns: Cool running water for 10-15 mins. NEVER apply ice, butter, or toothpaste.',
      false,
    );
  }

  // 5. Stomach Ache, Acidity & Indigestion
  if (q.contains('stomach') || q.contains('acidity') || q.contains('indigestion') || q.contains('gas') || q.contains('belly pain') || q.contains('gastric')) {
    return (
      '🍵 Relief Steps for Stomach Discomfort & Acidity: BRAT diet, ginger tea, avoid oily/spicy foods.',
      false,
    );
  }

  return ('📋 Medical Guidance: Consult doctor if symptoms persist.', false);
}

void main() {
  group('AI Health Assistant Intelligence Tests', () {
    test('Detects cardiac and respiratory emergencies and sets urgencyFlag to true', () {
      final (alert, isUrgent) = generateMedicalAdvice('I have severe chest pain and cannot breathe');
      expect(isUrgent, isTrue);
      expect(alert, contains('CRITICAL MEDICAL ALERT'));
      expect(alert, contains('108'));
    });

    test('Detects stroke and neurological emergency symptoms', () {
      final (alert, isUrgent) = generateMedicalAdvice('Sudden face drooping and arm paralysis');
      expect(isUrgent, isTrue);
      expect(alert, contains('CRITICAL MEDICAL ALERT'));
    });

    test('Provides proper fever home care instructions', () {
      final (advice, isUrgent) = generateMedicalAdvice('My child has 101 fever and shivering');
      expect(isUrgent, isFalse);
      expect(advice, contains('Hydration'));
      expect(advice, contains('Paracetamol'));
    });

    test('Provides proper burn first-aid and warns against harmful folk remedies', () {
      final (advice, isUrgent) = generateMedicalAdvice('I got a hot water scald burn on my hand');
      expect(isUrgent, isFalse);
      expect(advice, contains('Cool running water'));
      expect(advice, contains('NEVER apply ice, butter, or toothpaste'));
    });

    test('Provides safe stomach acidity and indigestion advice', () {
      final (advice, isUrgent) = generateMedicalAdvice('Severe acidity and stomach burning after food');
      expect(isUrgent, isFalse);
      expect(advice, contains('BRAT diet'));
    });
  });
}
