package funkin.backend.parsers;

class CodenameParser {
	public static function characterParse(xmlText:String):String {
	    var find = (tag:String, txt:String) -> {
	        var reTag = new EReg("<" + tag + ">([\\s\\S]*?)<\\/" + tag + ">", "i");
	        if (reTag.match(txt)) return reTag.matched(1);
	        var reAttr = new EReg(tag + '\\s*=\\s*"([^"]+)"', 'i');
	        if (reAttr.match(txt)) return reAttr.matched(1);
	        var reAttr2 = new EReg(tag + "\\s*=\\s*'([^']+)'", 'i');
	        if (reAttr2.match(txt)) return reAttr2.matched(1);
	        return null;
	    };

	    var esc = (s:String) -> if (s == null) "" else StringTools.replace(s, "\"", "\\\"");

	    var image = null;
	    if (find('sprite', xmlText) != null) image = find('sprite', xmlText);
	    else if (find('image', xmlText) != null) image = find('image', xmlText);
	    else image = '';

	    var scale = find('scale', xmlText);
	    var posx = find('x', xmlText);
	    var posy = find('y', xmlText);
	    var camx = find('camx', xmlText);
	    var camy = find('camy', xmlText);
	    var icon = find('icon', xmlText) != null ? find('icon', xmlText) : find('healthicon', xmlText);
	    var holdTime = find('hold', xmlText) != null ? find('hold', xmlText) : find('holdtime', xmlText);
	    var flipX = find('flipX', xmlText);
	    var antialiasing = find('antialiasing', xmlText);
	    var healthbar = find('color', xmlText);
	    var vocals = find('vocals', xmlText) != null ? find('vocals', xmlText) : find('vocals_file', xmlText);
	    var editorPlayer = find('_editor_isPlayer', xmlText);

	    var hcolors:Array<Int> = null;
	    if (healthbar != null) {
			var tempColor = FlxColor.fromString(healthbar);
	        hcolors = [tempColor.red, tempColor.green, tempColor.blue];
	    }

	    var obj = new StringBuf();
	    obj.add("{");
		var charPath:String = "characters/"+esc(image);
		var realPath:String = haxe.io.Path.withoutExtension("mods/"+Mods.currentModDirectory+"/images/"+charPath);
		if(FileSystem.isDirectory(realPath)){
			for (i => file in FileSystem.readDirectory(realPath)) {
				var full = realPath + "/" + file;
				if (file.contains(".xml") || FileSystem.isDirectory(full)) continue;
				var noExt = haxe.io.Path.withoutExtension(file);
				
				if(i == 0) charPath = charPath+"/"+noExt;
				else charPath += ", characters/"+esc(image)+"/"+noExt;
			}
		}
	    obj.add('\"image\":\"' + charPath + '\"');
	
	    if (flipX != null) {
	        var flipVal = (StringTools.ltrim(flipX).toLowerCase() == "true" || flipX == "1") ? "true" : "false";
	        obj.add(',\"flip_x\":' + flipVal);
			if(flipVal == "true"){
				if(camx != null){
					if(camx.startsWith("-")) camx = camx.substr(1, camx.length - 1);
					else camx = "-" + camx;
				}
			}
	    } else {
			obj.add(',\"flip_x\":false');
		}

	    if (scale != null) {
	        obj.add(',\"scale\":' + scale);
	    } else {
			obj.add(',\"scale\":1');
		}

	    if (posx != null || posy != null) {
	        var px = posx != null ? posx : "0";
	        var py = posy != null ? posy : "0";
	        obj.add(',\"position\":[' + px + ',' + py + ']');
	    } else {
			obj.add(',\"position\":[0,0]');
		}

	    if (camx != null || camy != null) {
	        var cx = camx != null ? camx : "0";
	        var cy = camy != null ? camy : "0";
	        obj.add(',\"camera_position\":[' + cx + ',' + cy + ']');
	    } else {
			obj.add(',\"camera_position\":[0,0]');
		}

	    if (icon != null) {
	        obj.add(',\"healthicon\":\"' + esc(icon) + '\"');
	    } else {
			obj.add(',\"healthicon\":\"face\"');
		}

	    if (holdTime != null) {
	        obj.add(',\"sing_duration\":' + holdTime);
	    } else {
			obj.add(',\"sing_duration\":4');
		}

	    if (antialiasing != null) {
	        var aaVal = (StringTools.ltrim(antialiasing).toLowerCase() == "true" || antialiasing == "1") ? "false" : "true";
	        obj.add(',\"no_antialiasing\":' + aaVal);
	    } else {
			obj.add(',\"no_antialiasing\": false');
		}

	    if (hcolors != null) {
	        obj.add(',\"healthbar_colors\":[' + hcolors[0] + ',' + hcolors[1] + ',' + hcolors[2] + ']');
	    } else {
			obj.add(',\"healthbar_colors\":[0,0,0]');
		}

	    if (vocals != null) obj.add(',\"vocals_file\":\"' + esc(vocals) + '\"');
	    else obj.add(',\"vocals_file\":\"\"');

	    if (editorPlayer != null) {
	        var edVal = (StringTools.ltrim(editorPlayer).toLowerCase() == "true" || editorPlayer == "1") ? "true" : "false";
	        obj.add(',\"_editor_isPlayer\":' + edVal);
	    } else {
	        obj.add(',\"_editor_isPlayer\":false');
	    }
		var animsArr = new Array<String>();

		var animBlock = find("animations", xmlText);
		var scanText = if (animBlock != null) animBlock else xmlText;

		var idx = 0;
		while (true) {
	    	var start = scanText.indexOf("<anim", idx);
	    	if (start == -1) break;

	    	var openEnd = scanText.indexOf(">", start);
	    	if (openEnd == -1) break;

	    	var openTag = scanText.substring(start, openEnd + 1);
	    	var closeTagIdx = -1;
	    	var contentInside = "";
	    	if (!StringTools.endsWith(openTag, "/>")) {
	    	    var closeTag = "</anim>";
	    	    var searchFrom = openEnd + 1;
	    	    closeTagIdx = scanText.indexOf(closeTag, searchFrom);
	    	    if (closeTagIdx != -1) {
	    	        contentInside = scanText.substring(searchFrom, closeTagIdx);
	    	        idx = closeTagIdx + closeTag.length;
	    	    } else {
	    	        idx = openEnd + 1;
	    	    }
			} else {
	    	    idx = openEnd + 1;
	    	}

	    	var getAttr = (tag:String, attr:String) -> {
	    	    var re = new EReg(attr + '\\s*=\\s*"(.*?)"', 'i');
	    	    if (re.match(tag)) return re.matched(1);
	    	    var re2 = new EReg(attr + "\\s*=\\s*'(.*?)'", 'i');
	    	    if (re2.match(tag)) return re2.matched(1);
	    	    return null;
	    	};

	    	var nameAttr    = getAttr(openTag, "anim");
	    	var animAttr    = getAttr(openTag, "name");
	    	var loopAttr    = getAttr(openTag, "loop");
	    	var fpsAttr     = getAttr(openTag, "fps");
	    	var xAttr       = getAttr(openTag, "x");
	    	var yAttr       = getAttr(openTag, "y");
	    	var indicesAttr = getAttr(openTag, "indices");

	    	if ((indicesAttr == null || indicesAttr == "") && contentInside != null && contentInside != "") {
	    	    var inner = StringTools.trim(contentInside);
	    	    var digitsRe = new EReg("^[0-9,\\s\\-]+$", "");
	    	    if (inner != "" && digitsRe.match(inner)) {
	    	        indicesAttr = inner;
	    	    }
	    	}

	    	var esc = (s:String) -> if (s == null) "" else StringTools.replace(s, "\"", "\\\"");

	    	var animObj = new StringBuf();
	    	animObj.add("{");
	    	animObj.add('"name":"' + esc(nameAttr) + '",');
	    	animObj.add('"anim":"' + esc(animAttr) + '"');

	    	if (loopAttr != null) animObj.add(',"loop":' + (loopAttr.toLowerCase() == "true" ? "true" : "false"));
			else animObj.add(',"loop":false');
	    	if (fpsAttr != null && fpsAttr != "") animObj.add(',"fps":' + fpsAttr);
			else animObj.add(',"fps":24');

	    	if (xAttr != null || yAttr != null) {
	    	    var ox = if (xAttr != null && xAttr != "") xAttr else "0";
	    	    var oy = if (yAttr != null && yAttr != "") yAttr else "0";
	    	    animObj.add(',"offsets":[' + ox + ',' + oy + ']');
	    	} else {
				animObj.add(',"offsets":[0,0]');
			}

	    	if (indicesAttr != null && indicesAttr != "") {
	    	    var norm:String = StringTools.replace(indicesAttr, "\"", "");
	    	    norm = StringTools.replace(norm, "'", "");
	    	    norm = StringTools.trim(norm);
				if(norm.contains("..")){
					var temp = CoolUtil.expandRange(norm);
					norm = temp.join(",");
				}
	    	    animObj.add(',"indices":[' + norm + ']');
	    	} else {
				animObj.add(',"indices":[]');
			}

	    	animObj.add("}");
	    	animsArr.push(animObj.toString());
		}

		obj.add(',"animations":[' + animsArr.join(",") + ']');

	    obj.add("}");
	    return obj.toString();
	}
}