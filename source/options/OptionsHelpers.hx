package options;

import sys.FileSystem;
import sys.io.File;

import options.Option;

class OptionsHelpers
{
	public static var colorblindFilterArray = ['None', 'Protanopia', 'Protanomaly', 'Deuteranopia','Deuteranomaly','Tritanopia','Tritanomaly','Achromatopsia','Achromatomaly'];
    public static var memoryTypeArray = ["Usage", "Reserved", "Current", "Large"];
    
}

class OptionsName
{
    
    //--------------TTF SETTING------------------------//
    
    public static function funcDisable():String{		
		return 'Disabled';
	}
	
	public static function funcEnable():String{			
		return 'Enabled';
	}
	
	public static function funcMS():String{		
		return 'MS';
	}
	
	public static function funcGrid():String{		
		return 'Grid';
	}
	
	//----------OPTION SETTING------------------------//

    public static function setGameplay():String{				
		return "Gameplay";
    }
    
    public static function setAppearance():String{				
		return "Appearance";
    }
    
    public static function setMisc():String{
        switch (ClientPrefs.data.language)
	    {
			case 0: //english
			    return "Misc";
			case 1: //chinese
			    return "杂项";
			case 2: //chinese
			    return "雜項";    
		}					
		return "Misc";
    }
    
    public static function setOpponentMode():String{
				
		return "Opponent Mode";
    }
    
    public static function setMenuExtend():String{				
		return "Menu Extend";
    }
    
    public static function setControls():String{				
		return "Controls";
    }
    
    //----------OPTION CAP------------------------//
    
    public static function setDownscrollOption():String{			
		return "Toggle making the notes scroll down rather than up.";
    }
    
    public static function displayDownscrollOption():String{				
		return "Downscroll";
    }
    
    //----------OPTION OptionCata------------------------//
    
    
    
}