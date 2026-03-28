package funkin.backend.parsers;

import haxe.Json;

class CodenameParser {
    public static function characterParse(xmlText:String):String {
        var xml = Xml.parse(xmlText).firstElement();
        var find = function(name:String):String {
            if (xml.exists(name)) return xml.get(name);
            var child = xml.elementsNamed(name).next();
            if (child != null && child.firstChild() != null) return child.firstChild().nodeValue;
            return null;
        };

        var image = find('sprite') ?? find('image') ?? '';
        var charPath:String = "characters/" + image;
        var realPath:String = haxe.io.Path.withoutExtension("mods/" + Mods.currentModDirectory + "/images/" + charPath);
        
        if (FileSystem.exists(realPath) && FileSystem.isDirectory(realPath)) {
            var files = FileSystem.readDirectory(realPath);
            for (i => file in files) {
                var full = realPath + "/" + file;
                if (file.contains(".xml") || FileSystem.isDirectory(full)) continue;
                
                var noExt = haxe.io.Path.withoutExtension(file);
                if (i == 0) charPath = charPath + "/" + noExt;
                else charPath += ", characters/" + image + "/" + noExt;
            }
        }

        var flipXRaw = find('flipX');
        var flipVal = (flipXRaw != null && (StringTools.ltrim(flipXRaw).toLowerCase() == "true" || flipXRaw == "1")) ? "true" : "false";
        
        var camx = find('camx');
        var camy = find('camy');

        if (flipVal == "true" && camx != null) {
            if (StringTools.startsWith(camx, "-")) camx = camx.substr(1);
            else camx = "-" + camx;
        }

        var antialiasing = find('antialiasing');
        var noAntialiasing = false;
        if (antialiasing != null) {
            noAntialiasing = (StringTools.ltrim(antialiasing).toLowerCase() == "true" || antialiasing == "1") ? false : true;
        }

        var hcolors = [0, 0, 0];
        var healthbar = find('color');
        if (healthbar != null) {
            var tempColor = FlxColor.fromString(healthbar);
            hcolors = [tempColor.red, tempColor.green, tempColor.blue];
        }

        var data = {
            image: charPath,
            flip_x: (flipVal == "true"),
            scale: Std.parseFloat(find('scale') ?? "1"),
            position: [
                Std.parseFloat(find('x') ?? "0"),
                Std.parseFloat(find('y') ?? "0")
            ],
            camera_position: [
                Std.parseFloat(camx ?? "0"),
                Std.parseFloat(camy ?? "0")
            ],
            healthicon: find('icon') ?? find('healthicon') ?? "face",
            sing_duration: Std.parseFloat(find('hold') ?? find('holdtime') ?? "4"),
            no_antialiasing: noAntialiasing,
            healthbar_colors: hcolors,
            vocals_file: find('vocals') ?? find('vocals_file') ?? "",
            _editor_isPlayer: (find('_editor_isPlayer') != null && (StringTools.ltrim(find('_editor_isPlayer')).toLowerCase() == "true" || find('_editor_isPlayer') == "1")),
            animations: []
        };

        var animBlock = xml.elementsNamed("animations").next() ?? xml;
        for (anim in animBlock.elementsNamed("anim")) {
            var animFind = function(a:Xml, name:String):String {
                if (a.exists(name)) return a.get(name);
                return null;
            };

            var indicesAttr = animFind(anim, "indices");
            if ((indicesAttr == null || indicesAttr == "") && anim.firstChild() != null) {
                var inner = StringTools.trim(anim.firstChild().nodeValue);
                if (new EReg("^[0-9,\\s\\-]+$", "").match(inner)) indicesAttr = inner;
            }

            var finalIndices:Array<Int> = [];
            if (indicesAttr != null && indicesAttr != "") {
                var norm = StringTools.replace(StringTools.replace(indicesAttr, "\"", ""), "'", "");
                norm = StringTools.trim(norm);
                if (norm.contains("..")) {
                    finalIndices = CoolUtil.expandRange(norm);
                } else {
                    finalIndices = norm.split(",").map(s -> Std.parseInt(StringTools.trim(s)));
                }
            }

            data.animations.push({
                name: animFind(anim, "anim"),
                anim: animFind(anim, "name"),
                loop: animFind(anim, "loop") == "true",
                fps: Std.parseInt(animFind(anim, "fps") ?? "24"),
                offsets: [
                    Std.parseFloat(animFind(anim, "x") ?? "0"),
                    Std.parseFloat(animFind(anim, "y") ?? "0")
                ],
                indices: finalIndices
            });
        }

        return Json.stringify(data, "\t");
    }
}