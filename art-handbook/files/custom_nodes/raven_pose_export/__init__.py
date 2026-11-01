import json, os
import folder_paths
class RavenSavePoseJSON:
 @classmethod
 def INPUT_TYPES(cls): return {'required':{'pose_json':('STRING',{'forceInput':True}),'filename_prefix':('STRING',{'default':'RavenPoseLibrary/pose'})}}
 RETURN_TYPES=()
 FUNCTION='save'
 OUTPUT_NODE=True
 CATEGORY='Raven/Pose Library'
 def save(self,pose_json,filename_prefix):
  data=json.loads(pose_json)
  if isinstance(data,list): data=data[0]
  if not isinstance(data,dict) or not data.get('people'): raise ValueError('No person in OpenPose JSON')
  folder,name,counter,subfolder,prefix=folder_paths.get_save_image_path(filename_prefix,folder_paths.get_output_directory())
  path=os.path.join(folder,f'{name}_{counter:05}.json')
  with open(path,'w',encoding='utf-8') as f: json.dump(data,f,indent=2)
  return {}
class RavenCleanNativeAlpha:
 @classmethod
 def INPUT_TYPES(cls):
  return {'required':{'image':('IMAGE',),'black_point':('FLOAT',{'default':0.06,'min':0.0,'max':0.3,'step':0.01}),'white_point':('FLOAT',{'default':0.94,'min':0.7,'max':1.0,'step':0.01})}}
 RETURN_TYPES=('IMAGE',)
 FUNCTION='clean'
 CATEGORY='Raven/Matte'
 def clean(self,image,black_point,white_point):
  if image.shape[-1]!=4: raise ValueError('Native RGBA image required; refusing to guess a mask from RGB')
  if white_point<=black_point: raise ValueError('Invalid alpha range')
  result=image.clone()
  alpha=((result[...,3:4]-black_point)/(white_point-black_point)).clamp(0,1)
  result[...,3:4]=alpha
  result[...,:3]=result[...,:3].masked_fill((alpha==0).expand_as(result[...,:3]),0)
  return (result,)
NODE_CLASS_MAPPINGS={'RavenSavePoseJSON':RavenSavePoseJSON,'RavenCleanNativeAlpha':RavenCleanNativeAlpha}
