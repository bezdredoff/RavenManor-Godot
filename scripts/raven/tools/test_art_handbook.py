import copy
import hashlib
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
import zipfile

TOOLS=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('art_book',TOOLS/'build_art_handbook.py')
book=importlib.util.module_from_spec(spec);spec.loader.exec_module(book)

class ArtHandbookTests(unittest.TestCase):
    def test_current_published_images_and_artifact_evidence(self):
        p=book.payload();data=p['catalog']
        self.assertEqual(len(data['assets']),154)
        self.assertEqual(len(data['recipes']),65)
        cup=next(a for a in data['assets'] if a['id']=='RM-M3-CUP-CHATGPT-CANDIDATE-V1')
        self.assertEqual(cup['status'],'pending_review')
        self.assertEqual(cup['image'],'assets/raven/match3/generated/cup-chatgpt-candidate-v1.png')
        self.assertEqual(cup['sha256'],'e02cdc758e54d1715d4cdc1bcf1e6db4a5cd46e45aea130dade2d9f7f8fed44d')
        self.assertEqual(sum(a['kind']=='character' for a in data['assets']),62)
        self.assertEqual(sum(a['kind']=='background' for a in data['assets']),26)
        self.assertEqual(sum(r['stage']=='inpaint' for r in data['recipes']),34)
        for r in data['recipes']:
            if r['stage']=='background':
                self.assertIsNone(r['parameters']['seed'])
                self.assertEqual(r['prompts'][0]['certainty'],'unavailable')
            if r['stage']=='inpaint':
                ui=json.loads((book.WEB/next(a['path'] for a in r['artifacts'] if a.get('kind')=='replay_ui')).read_text(encoding='utf-8'))
                api=json.loads((book.WEB/next(a['path'] for a in r['artifacts'] if a.get('kind')=='replay')).read_text(encoding='utf-8'))
                for node in ui['nodes']:
                    op=api[str(node['id'])]
                    if op['class_type']=='LoadImage':self.assertEqual(node['widgets_values'][0],op['inputs']['image'])
                    if op['class_type']=='SaveImage':self.assertEqual(node['widgets_values'][0],op['inputs']['filename_prefix'])

    def test_generated_files_are_current_and_no_gpu_default(self):
        for name,expected in book.generated(book.payload()).items():self.assertEqual((book.WEB/name).read_text(encoding='utf-8'),expected)
        result=subprocess.run([sys.executable,str(book.WEB/'files/scripts/run_replay.py'),'--recipe','inpaint-rowan-point_route'],capture_output=True,text=True)
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertIn('No files copied, models loaded or GPU job queued',result.stdout)

    def test_archive_download_is_complete_and_no_cache(self):
        with tempfile.TemporaryDirectory() as folder:
            # Use source roots explicitly: this verifies the exact ZIP builder.
            clone=Path(folder)/'book';clone.mkdir()
            import shutil
            for name in ['index.html','style.css','app.js','data.js','catalog.json','content.json']:shutil.copy2(book.WEB/name,clone/name)
            shutil.copytree(book.WEB/'files',clone/'files');shutil.copytree(book.WEB/'media',clone/'media')
            archive=book.make_download(clone)
            with zipfile.ZipFile(archive) as z:
                self.assertIsNone(z.testzip())
                self.assertIn('files/scripts/restore_protected_pixels.py',z.namelist())
                self.assertIn('files/settings/custom_emotions.json',z.namelist())
                self.assertFalse(any('__pycache__' in n or n.endswith('.safetensors') for n in z.namelist()))

    def test_protected_pixel_restoration_contract(self):
        import numpy as np
        from PIL import Image
        s=importlib.util.spec_from_file_location('restore',book.WEB/'files/scripts/restore_protected_pixels.py')
        restore=importlib.util.module_from_spec(s);s.loader.exec_module(restore)
        with tempfile.TemporaryDirectory() as folder:
            p=Path(folder);original=np.zeros((8,8,4),dtype=np.uint8);original[:,:,:3]=[45,80,120];original[:,:,3]=180
            raw=original.copy();raw[:,:,3]-=1;raw[3,3]=[220,30,20,255]
            mask=np.zeros((4,4),dtype=np.uint8);mask[1,1]=255
            Image.fromarray(original).save(p/'source.png');Image.fromarray(raw).save(p/'raw.png');Image.fromarray(mask).save(p/'mask.png')
            restore.restore(p/'source.png',p/'raw.png',p/'mask.png',[2,2,4,4],p/'out.png')
            out=np.array(Image.open(p/'out.png'));self.assertTrue(np.array_equal(out[0],original[0]));self.assertTrue(np.array_equal(out[3,3],raw[3,3]))
            raw[0,0,0]+=5;Image.fromarray(raw).save(p/'bad.png')
            with self.assertRaisesRegex(ValueError,'Unexpected changes'):restore.restore(p/'source.png',p/'bad.png',p/'mask.png',[2,2,4,4],p/'bad-out.png')

    def test_link_validation_refuses_escape(self):
        with self.assertRaises(ValueError):book.confined(book.WEB,'../outside.png')

if __name__=='__main__':unittest.main()
