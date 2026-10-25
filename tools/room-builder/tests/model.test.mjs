import test from 'node:test';
import assert from 'node:assert/strict';
import {exampleProject,validateProject,placeObject,topObjectAt,snap,pointInObject} from '../model.mjs';
test('sample schema and existing Raven ids',()=>{const p=validateProject(exampleProject());assert.equal(p.roomId,'RM-ROOM-HALL');assert.ok(p.objects.some(o=>o.assetRefId==='RM-ASSET-HALL-002'));});
test('snapping & duplicate tiles',()=>{const p=exampleProject();assert.equal(snap(33,40),40); const a=placeObject(p,'stone',41,45,'floor');assert.ok(a);assert.equal(placeObject(p,'stone',41,45,'floor'),null);});
test('z order and rotated hit tests',()=>{const p=exampleProject();const a=placeObject(p,'table',900,700,'foreground',false);assert.equal(topObjectAt(p,a.x+a.w/2,a.y+a.h/2)?.id,a.id);a.rotation=90;assert.ok(pointInObject(a.x+a.w/2,a.y+a.h/2,a));});
test('reject corrupted asset references and remote images',()=>{const p=exampleProject();p.objects[0].assetId='missing';assert.throws(()=>validateProject(p));p.objects[0].assetId='stairs';p.assets[0].image='https://example.com/asset.png';assert.throws(()=>validateProject(p));});
test('layer lock blocks edits',()=>{const p=exampleProject();p.layers[0].locked=true;assert.equal(placeObject(p,'wood',120,120,'floor'),null);});