package backend;

import states.MainMenuState;
#if DISCORD_ALLOWED
import Sys.sleep;
import lime.app.Application;
import hxdiscord_rpc.Discord;
import hxdiscord_rpc.Types;

class DiscordClient {
	public static var isInitialized:Bool = false;
	public static var isDiscordUser:Bool = false;
	public static var user:User; //Hold the current Discord user's info (Can be null!)

	/*
	 * Put your Discord RPC client ID here!
	 */
	private static final _defaultID:String = "1388450910056742932";
	public static var clientID(default, set):String = _defaultID;
	private static var presence:DiscordRichPresence = DiscordRichPresence.create();

	public static function check() {
		if(ClientPrefs.data.discordRPC) initialize();
		else if(isInitialized) shutdown();
	}

	public static function prepare() {
		if (!isInitialized && ClientPrefs.data.discordRPC) initialize();

		Application.current.window.onClose.add(function() {
			if(isInitialized) shutdown();
		});
	}

	public dynamic static function shutdown() {
		Discord.Shutdown();
		isInitialized = isDiscordUser = false;
		user = null;
	}

	private static function onReady(request:cpp.RawConstPointer<DiscordUser>):Void {
		var requestPtr:cpp.Star<DiscordUser> = cpp.ConstPointer.fromRaw(request).ptr;

		if (Std.parseInt(cast(requestPtr.discriminator, String)) != 0) //New Discord IDs/Discriminator system
			Log.info('Discord: Connected to User - ${cast(requestPtr.username, String)}#${cast(requestPtr.discriminator, String)}');
		else
			Log.info('Discord: Connected to User - ${cast(requestPtr.username, String)}');

		isDiscordUser = true;
		updateDiscordInfo(requestPtr);

		changePresence();
	}

	private static function onError(errorCode:Int, message:cpp.ConstCharStar):Void {
		Log.error('Discord: Error (${errorCode}: ${cast(message, String)})');
	}

	private static function onDisconnected(errorCode:Int, message:cpp.ConstCharStar):Void {
		Log.warn('Discord: Disconnected (${errorCode}: ${cast(message, String)})');
	}

	public static function initialize() {
		var discordHandlers:DiscordEventHandlers = DiscordEventHandlers.create();
		discordHandlers.ready = cpp.Function.fromStaticFunction(onReady);
		discordHandlers.disconnected = cpp.Function.fromStaticFunction(onDisconnected);
		discordHandlers.errored = cpp.Function.fromStaticFunction(onError);
		Discord.Initialize(clientID, cpp.RawPointer.addressOf(discordHandlers), 1, null);

		if(!isInitialized) Log.info("Discord Client initialized");

		sys.thread.Thread.create(() -> {
			var localID:String = clientID;
			while (localID == clientID) {
				#if DISCORD_DISABLE_IO_THREAD
				Discord.UpdateConnection();
				#end
				Discord.RunCallbacks();
				Sys.sleep(2);
			}
		});
		isInitialized = true;
	}

	public static function changePresence(?details:String = 'In the Menus', ?state:Null<String>, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float) {
		var startTimestamp:Float = 0;
		if (hasStartTimestamp) startTimestamp = Date.now().getTime();
		if (endTimestamp > 0) endTimestamp = startTimestamp + endTimestamp;

		presence.details = details;
		presence.state = state;
		presence.largeImageKey = 'icon';
		presence.largeImageText = "NotePulse Engine v" + MainMenuState.npeVersion;
		presence.smallImageKey = smallImageKey;
		presence.startTimestamp = Std.int(startTimestamp / 1000);
		presence.endTimestamp = Std.int(endTimestamp / 1000);
		updatePresence();

		presence.button1Label = "NotePulse Engine";
		presence.button1Url = "https://github.com/Manganosl/NotePulse-Engine";
	}

	public static function updateDiscordInfo(discReq:cpp.Star<DiscordUser>) {
		if(discReq == null) return;
		
		var _discriminator:Int = Std.parseInt(cast(discReq.discriminator, String));
		user = {
			userId: cast(discReq.userId, String),
			username: cast(discReq.username, String),
			discriminator: _discriminator,
			avatar: cast(discReq.avatar, String),
			globalName: cast(discReq.globalName, String),
			bot: cast(discReq.bot, Bool),
			flags: cast(discReq.flags, Int),
			premiumType: cast(discReq.premiumType, NitroType),
			//This looks so sloppy
			handle: ((_discriminator != 0) ? '${cast(discReq.username, String)}#${_discriminator}' : cast(discReq.username, String))
		};
	}

	public static function updatePresence()
		Discord.UpdatePresence(cpp.RawConstPointer.addressOf(presence));

	public static function resetClientID()
		clientID = _defaultID;

	private static function set_clientID(newID:String) {
		var change:Bool = (clientID != newID);
		clientID = newID;

		if(change && isInitialized) {
			shutdown();
			initialize();
			updatePresence();
		}
		return newID;
	}

	#if MODS_ALLOWED
	public static function loadModRPC() {
		var pack:Dynamic = Mods.getPack();
		if(pack != null && pack.discordRPC != null && pack.discordRPC != clientID) {
			clientID = pack.discordRPC;
		} else {
			resetClientID();
		}
	}
	#end

	#if LUA_ALLOWED
	public static function addLuaCallbacks(lua:State) {
		Lua_helper.add_callback(lua, "changeDiscordPresence", function(details:String, state:Null<String>, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float) {
			changePresence(details, state, smallImageKey, hasStartTimestamp, endTimestamp);
		});

		Lua_helper.add_callback(lua, "changeDiscordClientID", function(?newID:String = null) {
			if(newID == null) newID = _defaultID;
			clientID = newID;
		});
	}
	#end
}
#else
class DiscordClient {
	public function new() { throw "The Discord API is not supported on this platform!"; }
}
#end

typedef User = {
	userId:String,
	username:String,
	discriminator:Int,
	avatar:String,
	globalName:String,
	bot:Bool,
	flags:Int,
	premiumType:NitroType,
	handle:String
}

enum abstract NitroType(Int) to Int from Int {
	var NONE = 0;
	var NITRO_CLASSIC = 1;
	var NITRO = 2;
	var NITRO_BASIC = 3;
}