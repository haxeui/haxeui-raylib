package haxe.ui.backend;

import RayLib.*;
import RayLib.Texture2D;
import RayLib.Colors.*;

class ImageDisplayImpl extends ImageBase {
    private var _texture:Texture2D;
    
    private override function validateData() {
        if (_imageInfo != null) {
            dispose();
            _texture = _imageInfo.data.texture;
            if (_imageWidth <= 0) {
                _imageWidth = _imageInfo.width;
            }
            if (_imageHeight <= 0) {
                _imageHeight = _imageInfo.height;
            }
            aspectRatio = _imageInfo.width / _imageInfo.height;
        } else {
            dispose();
            _imageWidth = 0;
            _imageHeight = 0;
        }
    }
    
    public function draw(x:Int, y:Int) {
        var ix = x + _left;
        var iy = y + _top;

        if (_imageWidth != _imageInfo.width || _imageHeight != _imageInfo.height) {
            DrawTexture(_texture, Std.int(ix), Std.int(iy), WHITE);
        } else {
            DrawTexture(_texture, Std.int(ix), Std.int(iy), WHITE);
        }
    }
}
