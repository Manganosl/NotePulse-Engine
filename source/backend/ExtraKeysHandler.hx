package backend;

import flixel.input.keyboard.FlxKey;

class ExtraKeysHandler {
    public static var instance:ExtraKeysHandler;

    public var data:ExtraKeysData;

    public function new() {
        reloadExtraKeys();
    }

    public function reloadExtraKeys() {
        Log.hxTrace('Loading Extra Keys data...');

        var parser = new json2object.JsonParser<ExtraKeysData>();
        var dataPath:String = 'data/extrakeys.json';
        var dataText:String = Paths.getTextFromFile(dataPath);
		parser.fromJson(dataText);
		data = parser.value;

        Log.info('Load complete.');
    }

    static var widthData:Array<{x:Float, y:Float}> = [
        { x:106.4,        y:-8 },
        { x:90.44,        y:-10 },
        { x:76.874,       y:-12.5 },
        { x:65.3429,      y:-14 },
        { x:55.541465,    y:-16 },
        { x:47.21024525,  y:-17 },
        { x:40.1287084625,y:-18 },
        { x:34.109402193125, y:-19.5 },
        { x:28.9929918641563, y:-20 }
    ];

    public static function calculateWidth(received:Float):Float {
        for (point in widthData) {
            if (received == point.x) {
                return point.y;
            }
        }

        for (i in 0...widthData.length - 1) {
            var p1 = widthData[i];
            var p2 = widthData[i + 1];

            if (received < p1.x && received > p2.x) {
                var t = (received - p1.x) / (p2.x - p1.x);
                return p1.y + t * (p2.y - p1.y);
            }
        }

        if (received > widthData[0].x) {
            return extrapolate(received, widthData[0], widthData[1]);
        }

        var last = widthData.length - 1;
        return extrapolate(received, widthData[last], widthData[last - 1]);
    }

    static function extrapolate(x:Float, p1:{x:Float, y:Float}, p2:{x:Float, y:Float}):Float {
        var slope = (p2.y - p1.y) / (p2.x - p1.x);
        return p1.y + slope * (x - p1.x);
    }
}

class ExtraKeysData {
    // indexing
    public var keys:Array<EKManiaMode>;

    // these are only used to set the colors into your save data!
    public var colors:Array<EKNoteColor>;
    public var pixelNoteColors:Array<EKNoteColor>;

    public var animations:Array<EKAnimation>;
    public var maxKeys:Int;
    public var minKeys:Int;

    // these are used to set your keybinds into your save data!
    // also used when you click the Default Reset button
    public var keybinds:Array<Array<Array<Int>>>;

    // I said i wouldnt, but here it is! Anyway...
    public var scales:Array<Float>;

    // I also said this wouldnt be here
    public var pixelScales:Array<Float>;
}

class EKManiaMode {
    // 4k = 0,1,2,3
    public var notes:Array<Int>;
}

class EKNoteColor {
    public var inner:String;
    public var border:String;
    public var outline:String;

    public function new(){}
}

class EKAnimation {
    // arrowLEFT
    public var strum:String;

    // left confirm
    public var anim:String;

    // purple hold end
    public var note:String;

    // singLEFT
    public var sing:String;

    // 0
    public var pixel:Int;
}