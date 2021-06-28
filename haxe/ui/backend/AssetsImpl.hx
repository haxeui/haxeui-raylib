package haxe.ui.backend;

import cpp.NativeArray;
import haxe.Resource;
import haxe.io.Bytes;
import haxe.ui.assets.ImageInfo;
import RayLib.*;
import haxe.ui.backend.ImageData;

class AssetsImpl extends AssetsBase {
    private override function getImageFromHaxeResource(resourceId:String, callback:String->ImageInfo->Void) {
        var bytes:Bytes = Resource.getBytes(resourceId);
        imageFromBytes(bytes, function(imageInfo) {
            callback(resourceId, imageInfo);
        });
    }

    public override function imageFromBytes(bytes:Bytes, callback:ImageInfo->Void) {
        var p = NativeArray.address(bytes.getData(), 0);
        var image = LoadImageFromMemory(extensionFromMagicBytes(bytes), p, bytes.length);
        var texture = LoadTextureFromImage(image);
        UnloadImage(image);
        
        var imageData = new ImageData();
        imageData.texture = texture;
        
        callback({
            data: imageData,
            width: image.width,
            height: image.height
        });
    }
    
    // .jpg:  FF D8 FF
    // .png:  89 50 4E 47 0D 0A 1A 0A
    // .gif:  GIF87a
    //        GIF89a
    // .tiff: 49 49 2A 00
    //        4D 4D 00 2A
    // .bmp:  BM
    // .webp: RIFF ???? WEBP
    // .ico   00 00 01 00
    //        00 00 02 00 ( cursor files )
    private function extensionFromMagicBytes(bytes:Bytes):String {
        var ext = "";

        if (compareBytes(bytes, [0xFF, 0xD8, 0xFF]) == true) {
            ext = ".jpeg";
        } else if (compareBytes(bytes, [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]) == true) {
            ext = ".png";
        }

        return ext;
    }
    
    private function compareBytes(bytes:Bytes, startsWith:Array<Int>):Bool {
        var b = true;
        var i = 0;
        for (t in startsWith) {
            if (bytes.get(i) != t) {
                b = false;
                break;
            }
            i++;
        }
        return b;
    }
}