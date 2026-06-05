import shutil

src = r"C:\Users\Aiono\.gemini\antigravity-ide\brain\5d8d1f47-a40e-445d-b19f-25b257eec76e\farm_pixel_art_v2_1780580415514.png"
dst = r"C:\Users\Aiono\Desktop\KinkdomClicker\assets\buildings\farm.jpg"

try:
    shutil.copyfile(src, dst)
    print("Success")
except Exception as e:
    print(f"Error: {e}")
