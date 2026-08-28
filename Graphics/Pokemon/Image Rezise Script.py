from pathlib import Path
from PIL import Image, UnidentifiedImageError

SCALE = 2
SUPPORTED_EXTENSIONS = {".png", ".jpg", ".jpeg", ".bmp", ".gif", ".webp"}

SCRIPT_DIR = Path(__file__).parent.resolve()
OUTPUT_DIR = SCRIPT_DIR / "resized"
OUTPUT_DIR.mkdir(exist_ok=True)

processed = 0
skipped = 0
failed = 0

for image_path in SCRIPT_DIR.iterdir():
    if not image_path.is_file():
        continue

    if image_path.suffix.lower() not in SUPPORTED_EXTENSIONS:
        skipped += 1
        continue

    try:
        with Image.open(image_path) as img:
            img.load()  # Force-read the image now, so errors are caught here

            new_size = (img.width * SCALE, img.height * SCALE)
            resized = img.resize(new_size, Image.Resampling.NEAREST)

            output_path = OUTPUT_DIR / image_path.name
            resized.save(output_path)

            processed += 1
            print(f"Resized {image_path.name}: {img.width}x{img.height} -> {new_size[0]}x{new_size[1]}")

    except UnidentifiedImageError:
        failed += 1
        print(f"FAILED {image_path.name}: not a valid image file")

    except Exception as e:
        failed += 1
        print(f"FAILED {image_path.name}: {e}")

print()
print(f"Done. Resized: {processed}, skipped: {skipped}, failed: {failed}")