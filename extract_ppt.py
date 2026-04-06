#!/usr/bin/env python3
import zipfile
import xml.etree.ElementTree as ET
import os
from pathlib import Path

def extract_ppt_content(ppt_path):
    """Extract text and structure from PPTX file"""
    
    try:
        with zipfile.ZipFile(ppt_path, 'r') as zip_ref:
            # Get list of slide files
            slide_files = [f for f in zip_ref.namelist() if f.startswith('ppt/slides/slide') and f.endswith('.xml') and not 'rels' in f]
            slide_files.sort()
            
            print(f"📊 Total Slides: {len(slide_files)}\n")
            print("=" * 80)
            
            all_content = []
            
            for idx, slide_file in enumerate(slide_files, 1):
                print(f"\n📑 SLIDE {idx}:")
                print("-" * 80)
                
                # Read and parse the slide XML
                slide_xml = zip_ref.read(slide_file)
                root = ET.fromstring(slide_xml)
                
                # Define namespace
                namespace = {
                    'a': 'http://schemas.openxmlformats.org/drawingml/2006/main',
                    'p': 'http://schemas.openxmlformats.org/presentationml/2006/main',
                    'r': 'http://schemas.openxmlformats.org/officeDocument/2006/relationships'
                }
                
                # Extract all text from the slide
                text_elements = root.findall('.//a:t', namespace)
                
                slide_content = []
                if text_elements:
                    for elem in text_elements:
                        if elem.text:
                            print(elem.text)
                            slide_content.append(elem.text)
                else:
                    print("[No text content]")
                
                all_content.append({
                    'slide': idx,
                    'content': slide_content
                })
            
            print("\n" + "=" * 80)
            return all_content
    
    except Exception as e:
        print(f"❌ Error: {e}")
        return None

# Try to find the PPT file
ppt_locations = [
    Path(os.path.expanduser("~")) / "AppData" / "Local" / "Temp" / "updated_codemate_ai (1).pptx",
    Path("updated_codemate_ai (1).pptx"),
    Path(os.path.expanduser("~")) / "Downloads" / "updated_codemate_ai (1).pptx",
]

ppt_path = None
for loc in ppt_locations:
    if loc.exists():
        ppt_path = loc
        break

# If not found by exact name, search
if not ppt_path:
    temp_dir = Path(os.path.expanduser("~")) / "AppData" / "Local" / "Temp"
    for file in temp_dir.rglob("*.pptx"):
        if "codemate" in file.name.lower() or "ai" in file.name.lower():
            ppt_path = file
            break

if ppt_path:
    print(f"✅ Found PPT: {ppt_path}\n")
    extract_ppt_content(ppt_path)
else:
    print("❌ PPT file not found in expected locations")
    print("\nSearching for all .pptx files...")
    temp_dir = Path(os.path.expanduser("~")) / "AppData" / "Local" / "Temp"
    pptx_files = list(temp_dir.rglob("*.pptx"))
    for f in pptx_files[:10]:
        print(f"  - {f}")
