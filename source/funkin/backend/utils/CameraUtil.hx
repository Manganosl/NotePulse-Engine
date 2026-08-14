package funkin.backend.utils;

class CameraUtil {
    public function imitateCamera(cam:FlxCamera, base:FlxCamera){
        cam.scroll.x = base.scroll.x;
        cam.scroll.y = base.scroll.y;
        cam.angle = base.angle;
        cam.zoom = base.zoom;
    }
}