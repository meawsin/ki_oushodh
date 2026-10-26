import os
import textwrap
from PIL import Image, ImageDraw, ImageFont, ImageFilter

def create_vector_icon(icon_type, color, size=36):
    """Generates crisp, high-contrast vector icon badges."""
    icon = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(icon)
    
    # Rounded badge container with subtle translucent tint
    d.rounded_rectangle(
        [0, 0, size - 1, size - 1],
        radius=10,
        fill=(color[0], color[1], color[2], 36),
        outline=(color[0], color[1], color[2], 120),
        width=1
    )
    
    if icon_type == 'chip': # Edge AI Processor
        # Core rectangle
        d.rounded_rectangle([10, 10, 25, 25], radius=3, fill=(color[0], color[1], color[2], 70), outline=color, width=1)
        # Center glowing node
        d.ellipse([15, 15, 20, 20], fill=color)
        # Connector pins
        for p in [13, 22]:
            d.line([(p, 4), (p, 9)], fill=color, width=1)
            d.line([(p, 26), (p, 31)], fill=color, width=1)
            d.line([(4, p), (9, p)], fill=color, width=1)
            d.line([(26, p), (31, p)], fill=color, width=1)
            
    elif icon_type == 'scan': # Viewfinder / Glare Normalization
        # 4 corner targeting brackets
        w = 2
        # top-left
        d.line([(8, 8), (15, 8)], fill=color, width=w)
        d.line([(8, 8), (8, 15)], fill=color, width=w)
        # top-right
        d.line([(27, 8), (20, 8)], fill=color, width=w)
        d.line([(27, 8), (27, 15)], fill=color, width=w)
        # bottom-left
        d.line([(8, 27), (15, 27)], fill=color, width=w)
        d.line([(8, 27), (8, 20)], fill=color, width=w)
        # bottom-right
        d.line([(27, 27), (20, 27)], fill=color, width=w)
        d.line([(27, 27), (27, 20)], fill=color, width=w)
        # Laser reticle horizontal beam & center dot
        d.line([(10, 17), (25, 17)], fill=(255, 255, 255, 230), width=1)
        d.ellipse([16, 15, 19, 18], fill=color)
        
    elif icon_type == 'audio': # Soundwaves / TTS Voice Readout
        # Speaker horn
        d.polygon([(8, 14), (13, 14), (18, 9), (18, 26), (13, 21), (8, 21)], fill=color)
        # Radiating sound waves
        d.arc([15, 12, 23, 23], start=295, end=65, fill=color, width=2)
        d.arc([13, 8, 28, 27], start=300, end=60, fill=color, width=2)
        
    elif icon_type == 'pill': # Medicine Index / Compendium
        # Angled capsule body
        d.rounded_rectangle([8, 11, 27, 24], radius=6, outline=color, width=2)
        d.line([(17, 11), (17, 24)], fill=color, width=2)
        d.rounded_rectangle([9, 12, 16, 23], radius=4, fill=(color[0], color[1], color[2], 130))
        # Medical cross dot
        d.ellipse([21, 16, 23, 18], fill=color)
        
    return icon


def create_phone_mockup(screenshot_path, target_screen_h=820, bezel=9, corner_radius=44):
    """Renders a flagship modern smartphone mockup with slim bezels, Gorilla glass sheen, and drop shadows."""
    sc = Image.open(screenshot_path).convert('RGBA')
    aspect = sc.width / sc.height
    screen_w = int(target_screen_h * aspect)
    screen_h = target_screen_h
    
    # Resample screenshot with Lanczos for razor-sharp clarity
    sc_resized = sc.resize((screen_w, screen_h), Image.Resampling.LANCZOS)
    
    phone_w = screen_w + bezel * 2
    phone_h = screen_h + bezel * 2
    inner_radius = max(12, corner_radius - bezel)
    
    # Screen clipping mask
    screen_mask = Image.new('L', (screen_w, screen_h), 0)
    draw_sc_mask = ImageDraw.Draw(screen_mask)
    draw_sc_mask.rounded_rectangle([0, 0, screen_w - 1, screen_h - 1], radius=inner_radius, fill=255)
    
    screen_clipped = Image.new('RGBA', (screen_w, screen_h), (0, 0, 0, 0))
    screen_clipped.paste(sc_resized, (0, 0), screen_mask)
    
    # Hardware: Centered camera punch hole pill
    draw_screen = ImageDraw.Draw(screen_clipped)
    cam_w, cam_h = 24, 12
    cam_x = (screen_w - cam_w) // 2
    cam_y = 12
    draw_screen.rounded_rectangle([cam_x, cam_y, cam_x + cam_w, cam_y + cam_h], radius=6, fill=(3, 4, 7, 255))
    draw_screen.ellipse([cam_x + 4, cam_y + 2, cam_x + 10, cam_y + 8], fill=(12, 20, 36, 255))
    draw_screen.ellipse([cam_x + 5, cam_y + 3, cam_x + 8, cam_y + 6], fill=(28, 55, 105, 255))
    
    # Specular Gorilla Glass gloss sheen (subtle diagonal gradient)
    glare = Image.new('RGBA', (screen_w, screen_h), (0, 0, 0, 0))
    draw_glare = ImageDraw.Draw(glare)
    poly = [(0, 0), (int(screen_w * 0.65), 0), (0, int(screen_h * 0.45))]
    draw_glare.polygon(poly, fill=(255, 255, 255, 10))
    screen_clipped = Image.alpha_composite(screen_clipped, glare)
    
    # Outer frame
    phone_frame = Image.new('RGBA', (phone_w, phone_h), (0, 0, 0, 0))
    draw_frame = ImageDraw.Draw(phone_frame)
    
    # Dark titanium chassis
    draw_frame.rounded_rectangle([0, 0, phone_w - 1, phone_h - 1], radius=corner_radius, fill=(16, 20, 28, 255))
    
    # Milled metallic edge rim
    draw_frame.rounded_rectangle([0, 0, phone_w - 1, phone_h - 1], radius=corner_radius, outline=(64, 76, 96, 255), width=2)
    
    # Inner dark bezel frame
    draw_frame.rounded_rectangle([bezel - 1, bezel - 1, phone_w - bezel, phone_h - bezel], radius=inner_radius + 1, fill=(5, 7, 10, 255))
    
    # Paste masked screen
    phone_frame.paste(screen_clipped, (bezel, bezel), screen_mask)
    
    # Speaker slit at top bezel
    spk_w, spk_h = 44, 3
    spk_x = (phone_w - spk_w) // 2
    spk_y = (bezel - spk_h) // 2
    draw_frame.rounded_rectangle([spk_x, spk_y, spk_x + spk_w, spk_y + spk_h], radius=1, fill=(45, 52, 65, 255))
    
    # Multi-stage realistic Gaussian drop shadows
    pad = 130
    shadow_w = phone_w + pad * 2
    shadow_h = phone_h + pad * 2
    
    # Pass 1: Ultra-soft ambient diffusion shadow
    s1 = Image.new('RGBA', (shadow_w, shadow_h), (0, 0, 0, 0))
    d1 = ImageDraw.Draw(s1)
    d1.rounded_rectangle([pad, pad + 32, pad + phone_w - 1, pad + phone_h + 31], radius=corner_radius, fill=(0, 0, 0, 140))
    s1_blur = s1.filter(ImageFilter.GaussianBlur(52))
    
    # Pass 2: Medium directional shadow
    s2 = Image.new('RGBA', (shadow_w, shadow_h), (0, 0, 0, 0))
    d2 = ImageDraw.Draw(s2)
    d2.rounded_rectangle([pad, pad + 16, pad + phone_w - 1, pad + phone_h + 15], radius=corner_radius, fill=(0, 0, 0, 160))
    s2_blur = s2.filter(ImageFilter.GaussianBlur(22))
    
    # Pass 3: Crisp contact shadow
    s3 = Image.new('RGBA', (shadow_w, shadow_h), (0, 0, 0, 0))
    d3 = ImageDraw.Draw(s3)
    d3.rounded_rectangle([pad, pad + 6, pad + phone_w - 1, pad + phone_h + 5], radius=corner_radius, fill=(0, 0, 0, 200))
    s3_blur = s3.filter(ImageFilter.GaussianBlur(8))
    
    combined_shadow = Image.alpha_composite(s1_blur, s2_blur)
    combined_shadow = Image.alpha_composite(combined_shadow, s3_blur)
    
    return phone_frame, combined_shadow, pad


def generate_portfolio_banner():
    CANVAS_W, CANVAS_H = 1920, 1080
    banner = Image.new('RGBA', (CANVAS_W, CANVAS_H), (7, 10, 15, 255))
    
    # ── 1. BACKGROUND WITH AMBIENT GRADIENT & GLOWS ───────────────────────
    bg = Image.new('RGBA', (CANVAS_W, CANVAS_H), (0, 0, 0, 0))
    draw_bg = ImageDraw.Draw(bg)
    for y in range(CANVAS_H):
        t = y / CANVAS_H
        r = int(9 * (1 - t) + 5 * t)
        g = int(13 * (1 - t) + 7 * t)
        b = int(21 * (1 - t) + 11 * t)
        draw_bg.line([(0, y), (CANVAS_W, y)], fill=(r, g, b, 255))
    banner = Image.alpha_composite(banner, bg)
    
    # Ambient glows
    glow = Image.new('RGBA', (CANVAS_W, CANVAS_H), (0, 0, 0, 0))
    draw_glow = ImageDraw.Draw(glow)
    # Warm amber glow behind results phone (accent color from AppTheme and yellow pill)
    draw_glow.ellipse([1320, 220, 1960, 860], fill=(255, 191, 0, 36))
    # Cyan glow behind scanner phone
    draw_glow.ellipse([980, 180, 1560, 760], fill=(77, 208, 225, 26))
    # Royal blue ambient glow behind top-left logo card (matching #0D47A1 app icon)
    draw_glow.ellipse([50, 40, 500, 490], fill=(13, 71, 161, 45))
    
    glow_blurred = glow.filter(ImageFilter.GaussianBlur(110))
    banner = Image.alpha_composite(banner, glow_blurred)
    
    # Subtle tech matrix grid dots
    grid_img = Image.new('RGBA', (CANVAS_W, CANVAS_H), (0, 0, 0, 0))
    draw_grid = ImageDraw.Draw(grid_img)
    spacing = 36
    for gx in range(36, CANVAS_W, spacing):
        for gy in range(36, CANVAS_H, spacing):
            draw_grid.ellipse([gx, gy, gx + 1.2, gy + 1.2], fill=(255, 255, 255, 11))
    banner = Image.alpha_composite(banner, grid_img)
    
    # ── FONTS ─────────────────────────────────────────────────────────────
    font_bold_56 = ImageFont.truetype('C:/Windows/Fonts/segoeuib.ttf', 56)
    font_bn_title = ImageFont.truetype('C:/Windows/Fonts/Nirmala.ttc', 40)
    font_sub_14 = ImageFont.truetype('C:/Windows/Fonts/segoeuib.ttf', 14)
    font_tag_12 = ImageFont.truetype('C:/Windows/Fonts/segoeuib.ttf', 12)
    font_head_26 = ImageFont.truetype('C:/Windows/Fonts/segoeuib.ttf', 26)
    font_desc_16 = ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf', 16)
    font_card_tag = ImageFont.truetype('C:/Windows/Fonts/segoeuib.ttf', 11)
    font_card_title = ImageFont.truetype('C:/Windows/Fonts/segoeuib.ttf', 19)
    font_card_body = ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf', 13)
    font_pill_phone = ImageFont.truetype('C:/Windows/Fonts/segoeuib.ttf', 11)
    font_footer = ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf', 12)
    
    left_x = 90
    draw = ImageDraw.Draw(banner)
    
    # ── 2. APP LOGO FLOATING CARD (TOP-LEFT) ──────────────────────────────
    card_size = 80
    card_y = 80
    
    # Multi-stage soft drop shadow for floating logo card
    card_shadow = Image.new('RGBA', (card_size + 48, card_size + 48), (0, 0, 0, 0))
    draw_cs = ImageDraw.Draw(card_shadow)
    # Ambient diffusion shadow
    draw_cs.rounded_rectangle([24, 30, 24 + card_size, 30 + card_size], radius=20, fill=(0, 0, 0, 160))
    card_shadow = card_shadow.filter(ImageFilter.GaussianBlur(14))
    banner.paste(card_shadow, (left_x - 24, card_y - 24), card_shadow)
    
    # Real Ki Oushodh App Icon
    app_icon_path = 'assets/images/app_icon.png'
    if not os.path.exists(app_icon_path):
        app_icon_path = 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png'
        
    raw_icon = Image.open(app_icon_path).convert('RGBA')
    icon_resized = raw_icon.resize((card_size, card_size), Image.Resampling.LANCZOS)
    
    # Rounded squircle mask matching app icon curvature
    mask = Image.new('L', (card_size, card_size), 0)
    draw_m = ImageDraw.Draw(mask)
    draw_m.rounded_rectangle([0, 0, card_size - 1, card_size - 1], radius=18, fill=255)
    
    logo_card = Image.new('RGBA', (card_size, card_size), (0, 0, 0, 0))
    logo_card.paste(icon_resized, (0, 0), mask)
    
    # Crisp outer rim highlight (amber accent)
    draw_lc = ImageDraw.Draw(logo_card)
    draw_lc.rounded_rectangle([0, 0, card_size - 1, card_size - 1], radius=18, outline=(255, 191, 0, 210), width=2)
    
    banner.paste(logo_card, (left_x, card_y), logo_card)
    
    # Category Subtitle in accent color (Upper-case, bold)
    sub_x = left_x + card_size + 20
    draw.text((sub_x, card_y + 10), "OFFLINE ASSISTIVE HEALTHCARE SYSTEM", fill=(255, 191, 0, 255), font=font_sub_14)
    
    # Status pill under eyebrow
    pill_w, pill_h = 286, 26
    pill_x, pill_y = sub_x, card_y + 38
    draw.rounded_rectangle([pill_x, pill_y, pill_x + pill_w, pill_y + pill_h], radius=13, fill=(255, 255, 255, 16), outline=(255, 255, 255, 28), width=1)
    # Emerald pulse dot
    draw.ellipse([pill_x + 12, pill_y + 8, pill_x + 21, pill_y + 17], fill=(16, 185, 129, 255))
    draw.text((pill_x + 28, pill_y + 5), "100% ON-DEVICE AI  •  ACCESSIBILITY FIRST", fill=(226, 232, 240, 240), font=font_tag_12)
    
    # ── 3. APP TITLE (BOLD 56PT) ──────────────────────────────────────────
    title_baseline = 246
    draw.text((left_x, title_baseline), "Ki Oushodh", fill=(255, 255, 255, 255), font=font_bold_56, anchor='ls')
    en_bbox = draw.textbbox((left_x, title_baseline), "Ki Oushodh", font=font_bold_56, anchor='ls')
    # Bengali subtitle in amber
    draw.text((en_bbox[2] + 18, title_baseline), "(কী ওষুধ)", fill=(255, 191, 0, 255), font=font_bn_title, anchor='ls')
    
    # ── 4. 2-LINE HEADLINE (PROBLEM SOLVED) & DESCRIPTION ─────────────────
    hl_y = 280
    draw.text((left_x, hl_y), "Empowering low-literacy & elderly patients", fill=(241, 245, 249, 255), font=font_head_26)
    draw.text((left_x, hl_y + 36), "to identify medicines instantly and safely.", fill=(241, 245, 249, 255), font=font_head_26)
    
    desc_y = 368
    desc_text = (
        "Engineered for resource-constrained environments, Ki Oushodh translates reflective blister-pack "
        "labels into immediate, jargon-free Bengali audio readouts — operating 100% offline with zero cloud latency."
    )
    wrapped_desc = textwrap.wrap(desc_text, width=82)
    cur_y = desc_y
    for line in wrapped_desc:
        draw.text((left_x, cur_y), line, fill=(148, 163, 184, 255), font=font_desc_16)
        cur_y += 25
        
    # ── 5. 2x2 FEATURE HIGHLIGHT CARDS ────────────────────────────────────
    features = [
        {
            "icon_type": "chip",
            "accent": (77, 208, 225), # Cyan
            "tag": "ON-DEVICE INFERENCE",
            "title": "100% Offline Edge ML",
            "desc": "Zero server dependency. High-speed OCR and fuzzy candidate matching run entirely on-device with zero mobile data consumption."
        },
        {
            "icon_type": "scan",
            "accent": (255, 191, 0), # Amber
            "tag": "BLISTER-PACK OCR",
            "title": "Foil-Glare Normalization",
            "desc": "5-tier algorithmic heuristic pipeline normalizes acute reflections from shiny foils, glued dosages (Napa500), and embossed spaced lettering."
        },
        {
            "icon_type": "audio",
            "accent": (56, 189, 248), # Sky Blue
            "tag": "AUDITORY LITERACY",
            "title": "Vernacular Bengali TTS",
            "desc": "Translates complex Latin indications into gentle, jargon-free 2-sentence Bangla speech designed specifically for low-literacy users."
        },
        {
            "icon_type": "pill",
            "accent": (52, 211, 153), # Mint Green
            "tag": "OFFLINE COMPENDIUM",
            "title": "15,500+ Medicine Index",
            "desc": "Offline compendium of 13,929 Bangladeshi pharmaceutical brands and 1,640 generics with dosage forms and indications."
        }
    ]
    
    grid_y_start = 464
    card_w, card_h = 394, 220
    gap_x, gap_y = 22, 22
    
    for i, feat in enumerate(features):
        row = i // 2
        col = i % 2
        cx = left_x + col * (card_w + gap_x)
        cy = grid_y_start + row * (card_h + gap_y)
        
        # Translucent glass card layer
        c_layer = Image.new('RGBA', (card_w, card_h), (0, 0, 0, 0))
        draw_c = ImageDraw.Draw(c_layer)
        
        # Subtle gradient from top to bottom
        for ly in range(card_h):
            ratio = ly / card_h
            r = int(18 * (1 - ratio) + 12 * ratio)
            g = int(24 * (1 - ratio) + 16 * ratio)
            b = int(36 * (1 - ratio) + 24 * ratio)
            draw_c.line([(0, ly), (card_w, ly)], fill=(r, g, b, 205))
            
        # Rounded corner mask for gradient
        c_mask = Image.new('L', (card_w, card_h), 0)
        draw_cm = ImageDraw.Draw(c_mask)
        draw_cm.rounded_rectangle([0, 0, card_w - 1, card_h - 1], radius=16, fill=255)
        
        c_final = Image.new('RGBA', (card_w, card_h), (0, 0, 0, 0))
        c_final.paste(c_layer, (0, 0), c_mask)
        draw_cf = ImageDraw.Draw(c_final)
        
        # Subtle glass border
        draw_cf.rounded_rectangle([0, 0, card_w - 1, card_h - 1], radius=16, outline=(255, 255, 255, 24), width=1)
        # Top metallic rim highlight
        draw_cf.line([(16, 0), (card_w - 17, 0)], fill=(255, 255, 255, 55), width=1)
        
        # Draw vector icon badge
        v_icon = create_vector_icon(feat["icon_type"], feat["accent"], size=34)
        c_final.paste(v_icon, (20, 18), v_icon)
        
        # Tag text beside icon
        acc = feat["accent"]
        draw_cf.text((64, 27), feat["tag"], fill=(acc[0], acc[1], acc[2], 255), font=font_card_tag)
        
        # Feature title
        draw_cf.text((20, 64), feat["title"], fill=(255, 255, 255, 255), font=font_card_title)
        
        # Feature description
        wrapped_cdesc = textwrap.wrap(feat["desc"], width=42)
        desc_line_y = 104
        for line in wrapped_cdesc:
            draw_cf.text((20, desc_line_y), line, fill=(148, 163, 184, 255), font=font_card_body)
            desc_line_y += 21
            
        banner.paste(c_final, (cx, cy), c_final)
        
    # Technical credibility footer bar
    footer_text = "Clean Architecture (MVVM)  •  Google ML Kit Edge OCR  •  Flutter 3.x  •  Offline Hive NoSQL  •  Zero Telemetry"
    draw.text((left_x, 966), footer_text, fill=(100, 116, 139, 230), font=font_footer)
    
    # ── 6. RIGHT HALF: TWO OVERLAPPING SMARTPHONES ────────────────────────
    # Secondary Phone (Background - Camera Scanner View)
    scan_screenshot = 'screenshots/ki_oushodh(Scanning).png'
    phone_sec, shadow_sec, pad_sec = create_phone_mockup(scan_screenshot, target_screen_h=790, bezel=9, corner_radius=42)
    sec_x, sec_y = 1115, 120
    
    # Floating tag above secondary phone
    tag_sec = Image.new('RGBA', (210, 26), (0, 0, 0, 0))
    d_ts = ImageDraw.Draw(tag_sec)
    d_ts.rounded_rectangle([0, 0, 209, 25], radius=13, fill=(15, 20, 30, 210), outline=(77, 208, 225, 160), width=1)
    d_ts.ellipse([10, 8, 18, 16], fill=(77, 208, 225, 255))
    d_ts.text((24, 6), "CAMERA OPTICAL SCANNER", fill=(203, 213, 225, 255), font=font_pill_phone)
    banner.paste(tag_sec, (sec_x + (phone_sec.width - 210) // 2, sec_y - 36), tag_sec)
    
    # Paste secondary shadow, then secondary phone
    banner.paste(shadow_sec, (sec_x - pad_sec, sec_y - pad_sec), shadow_sec)
    banner.paste(phone_sec, (sec_x, sec_y), phone_sec)
    
    # Primary Phone (Foreground - Identification Result & Vernacular TTS)
    res_screenshot = 'screenshots/ki_oushodh(Result).png'
    phone_pri, shadow_pri, pad_pri = create_phone_mockup(res_screenshot, target_screen_h=835, bezel=9, corner_radius=42)
    pri_x, pri_y = 1405, 110
    
    # Floating tag above primary phone
    tag_pri = Image.new('RGBA', (230, 26), (0, 0, 0, 0))
    d_tp = ImageDraw.Draw(tag_pri)
    d_tp.rounded_rectangle([0, 0, 229, 25], radius=13, fill=(15, 20, 30, 210), outline=(255, 191, 0, 180), width=1)
    d_tp.ellipse([10, 8, 18, 16], fill=(255, 191, 0, 255))
    d_tp.text((24, 6), "IDENTIFIED RESULT & AUDIO TTS", fill=(255, 255, 255, 255), font=font_pill_phone)
    banner.paste(tag_pri, (pri_x + (phone_pri.width - 230) // 2, pri_y - 36), tag_pri)
    
    # Paste primary shadow (falls over canvas AND over secondary phone)
    banner.paste(shadow_pri, (pri_x - pad_pri, pri_y - pad_pri), shadow_pri)
    banner.paste(phone_pri, (pri_x, pri_y), phone_pri)
    
    # ── 7. SAVE OUTPUT ────────────────────────────────────────────────────
    os.makedirs('assets/images', exist_ok=True)
    out_path = 'assets/images/Ki_ousudh_banner.png'
    banner.save(out_path, format='PNG', optimize=True)
    print(f"Generated showcase banner successfully: {out_path}")
    
    # Also save alternative spelling
    alt_path = 'assets/images/Ki_oushodh_banner.png'
    banner.save(alt_path, format='PNG', optimize=True)

if __name__ == '__main__':
    generate_portfolio_banner()
