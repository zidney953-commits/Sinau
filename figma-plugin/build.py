# Membuat code.js dari builder.template.js + gambar di folder images/ (base64).
import base64, json, os
here = os.path.dirname(os.path.abspath(__file__))
imgs = {}
for f in sorted(os.listdir(os.path.join(here, 'images'))):
    if f.endswith('.jpg'):
        imgs[f[:-4]] = base64.b64encode(open(os.path.join(here, 'images', f), 'rb').read()).decode()
tpl = open(os.path.join(here, 'builder.template.js'), encoding='utf-8').read()
open(os.path.join(here, 'code.js'), 'w', encoding='utf-8').write(tpl.replace('__IMAGES__', json.dumps(imgs)))
print(len(imgs), 'gambar ·', os.path.getsize(os.path.join(here, 'code.js')) // 1024, 'KB')
