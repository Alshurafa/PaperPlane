#rem
	Notes:
		
	ToDo:
( )		AI Computer player
( )		Multiplayer
( )		Online score
( )		Vibration easter egg
( )		Luck doors option
( )		Ads

#end

' Strict code mode please
Strict



#ANDROID_APP_LABEL="Zoohra"
#ANDROID_APP_PACKAGE="com.ma1ak.Zoohra"
#ANDROID_SCREEN_ORIENTATION="landscape"


' The modules
Import mojo
Import diddy.src.diddy.framework
Import diddy.src.diddy.functions
Import fontmachine
Import myGUI
'Import admob

Global game:MyGame

' Starting Point
Function Main:Int()
	game = New MyGame()
	Return 0
End

' Screens in the game
Global splashScreen:Screen = New SplashScreen()
Global demoScreen:Screen = New DemoScreen()
Global titleScreen:Screen = New TitleScreen()
Global levelScreen:Screen = New LevelScreen()
Global storyScreen:Screen = New StoryScreen()
Global startScreen:Screen = New StartScreen()
Global gameScreen:Screen = New GameScreen()
Global gameOverScreen:Screen
Global vc:VirtualController
Global options:Options = New Options()
Global gameControl:GameControl = New GameControl()


'Moster types
Global e1:Int = 110	'pencil enemy
Global e2:Int = 112	'ink enemy
Global f1:Int = 120 'Fire
Global f2:Int = 122 'FireBall
Global a1:Int = 130 'small plane
Global p1:Int = 210	'paper ball
Global r1:Int = 301	'ruler
Global r2:Int = 302 'crushed into ruler
Global i1:Int = 010	'inkwell
Global h1:Int = 020	'heart
Global s1:Int = 030 'invisible shield

Global dH:Float
Global dW:Float

Global version:Float = 1.21
Global fmt$
Global score:Int
Global highscore:Int
Global highlevel:Int
Global level:Int			'keep track of levels
Global currentLvl:Lvl
Global levels:Lvl[60]
Global unlocked:Int
Global whiteFont:BitmapFont
Global blackFont:BitmapFont

'summary: The Main Game Class
Class MyGame Extends DiddyApp
	Field state$
	
	'summary: Load state, images, sounds, and fonts + assign Global Varibles
	Method OnCreate:Int()
		Super.OnCreate()
		SetUpdateRate(60)
		' Set the default font
		SetFont(LoadImage("graphics/font/font.png",32,32,91))			'ToDo: Create another font 16x16x91 for low end devices
		'set an alternative fontmachine
		whiteFont = New BitmapFont("graphics/font/whiteFont.txt", False)
		blackFont = New BitmapFont("graphics/font/blackFont.txt", False)
		SetScreenSize(1920, 1080)
		
		#If TARGET="glfw" Or TARGET="xna"
			fmt=".wav"
		#Else
			fmt=".mp3"
			If GetBrowserName()="Firefox" Then fmt=".wav"
		#End
		
		#If TARGET="glfw"
			ShowMouse()
		#End
		
		LoadImages()
		LoadSounds()
		
		dH=SCREEN_HEIGHT
		dW=SCREEN_WIDTH
		highscore=0
		vc= New VirtualController()
		splashScreen.PreStart()
		options.Start()
		gameControl.Start()
		
		initLevels()
		
		state=LoadState()
		If state
			Local stat:=state.Split(" ")
			Local version:Float=Float(stat[0].Trim())
			level=Int(stat[1].Trim())
			highscore=Int(stat[2].Trim())
			options.soundV=Float(stat[3].Trim())
			options.musicV=Float(stat[4].Trim())
			gameControl.x=Float(stat[5].Trim())
			gameControl.y=Float(stat[6].Trim())
			gameControl.sensitivity=Float(stat[7].Trim())
			options.soundF=Bool(stat[8].Trim())
			options.musicF=Bool(stat[9].Trim())
			options.soundBox.checked=options.soundF
			options.musicBox.checked=options.musicF
			For Local count:Int=10 To 69
				Local lvl:=stat[count].Split("/")
				levels[count-10].score=Int(lvl[0].Trim())
				levels[count-10].grade=Float(lvl[1].Trim())
				If levels[count-10].grade<>0 And count<>69
					levels[count-9].locked=False
				End
			End
		End
		Return 0
	End
	
	Method OnLoading:Int()
		DrawBG(game.images.Find("ma1ak").image)
		Return 0
	End
	
	'summary: Create 60 levels
	Method initLevels:Void()
		Local count:Int=0
		Local line:Int=1
		Local imgs:GameImage[11]
		imgs[0]=game.images.Find("shot")
		imgs[1]=game.images.Find("line13")
		imgs[2]=game.images.Find("line21")
		imgs[3]=game.images.Find("line22")
		imgs[4]=game.images.Find("line23")
		imgs[5]=game.images.Find("line31")
		imgs[6]=game.images.Find("line32")
		imgs[7]=game.images.Find("line33")
		imgs[8]=game.images.Find("line41")
		imgs[9]=game.images.Find("line42")
		imgs[10]=game.images.Find("line43")
		For Local ch:Int=1 To 4
			For Local o:Int=1 To 3
				For Local i:Int=1 To 5
					levels[count]= New Lvl(count+1,(dW*.08*i+game.images.Find("note").w*i)-dW*.05,dH*.1*o+game.images.Find("note").h*o)
					levels[count].monsters=i*10
					If line>1
						levels[count].icon=imgs[line-2]
					End
					If count>=50
						levels[count].enemyType=f2
						levels[count].enemyImg=game.images.Find("ball")
					Elseif count>=45
						levels[count].enemyType=f1
						levels[count].enemyImg=game.images.Find("fire")
					Elseif count>=40
						levels[count].visibility=3
					Elseif count>=35
						levels[count].visibility=2
					Elseif count>=30
						levels[count].visibility=1
					Elseif count>=25
						levels[count].visiblePlane=False
					Elseif count>=20
						levels[count].enemyType=a1
						levels[count].enemyImg=game.images.Find("smallPlane")
						levels[count].inkF=False
					Elseif count>=15
						levels[count].enemyType=e2
					End
					
					If o>2
						levels[count].objects=i*2
					End
					levels[count].speed=.9
					levels[count].speed+=i*.1
					count+=1
				End
				line+=1
			End
		End
	End
	
	'summary: Pause game on suspend
	Method OnSuspend:Int()
		options.pause=True
		options.SaveInfo()
		Return 0
	End
	
	'summary: Load Images
	Method LoadImages:Void()
	
		' create tmpImage for animations
		Local tmpImage:Image
		
		'If not False or True, it is True by default but I will change it later
		images.Load("board.png", "", False)
		images.Load("ma1ak.png", "", False)
		images.Load("bg.png", "", False)
		images.Load("ch1.png", "", False)
		images.Load("ch2.png", "", False)
		images.Load("ch3.png", "", False)
		images.Load("ch4.png", "", False)
		images.Load("titleBG.png", "", False)

		images.Load("line13.png")
		images.Load("line21.png")
		images.Load("line22.png")
		images.Load("line23.png")
		images.Load("line31.png")
		images.Load("line32.png")
		images.Load("line33.png")
		images.Load("line41.png")
		images.Load("line42.png")
		images.Load("line43.png")
		
		images.Load("stickman.png")
		
		images.Load("backHome.png", "", False)
		images.Load("backPage.png", "", True)
		images.Load("gameoverFooter.png", "", False)
		images.Load("title.png", "", True)
		images.Load("subtitle.png", "", True)
		images.Load("classic.png", "", False)
		images.Load("survival.png", "", False)
		images.Load("page_corner.png", "", False)
		
		images.Load("soundOn.png", "", False)
		images.Load("soundOff.png", "", False)
		images.Load("musicOn.png", "", False)
		images.Load("musicOff.png", "", False)
		
		images.Load("note.png", "", True)
		images.Load("lock.png", "", True)
		
		images.Load("smallPlane.png", "", True)
		images.Load("scissors.png", "", True)
		images.Load("ruler.png", "", True)
		images.Load("drop.png", "", True)
		images.Load("inkwell.png", "")
		images.Load("lives.png", "", True)
		images.Load("invisible.png", "", True)
		images.Load("eraser.png", "", False)
		images.Load("fog.png", "", False)
		
		images.Load("clipboard.png", "", True)
		
		images.Load("pause.png", "", False)
		images.Load("resume.png", "", False)
		images.Load("home.png", "", False)
		images.Load("redo.png", "", False)
		images.Load("next.png", "", False)
		images.Load("levelMenu.png", "", False)
		
		images.Load("options/calibrate.png", "", False)
		images.Load("options/reset.png", "", False)
		images.Load("options/default.png", "", False)
		images.Load("options/save.png", "", False)
		images.Load("options/ignore.png", "", False)
		images.Load("options/incBtn.png", "", False)
		images.Load("options/decBtn.png", "", False)
		images.Load("options/options.png", "",False)
		images.Load("options/circle.png", "")
		images.Load("options/tiltOp.png", "")
		images.Load("options/keyboardOp.png", "")
		images.Load("options/virtualOp.png", "")
		images.Load("options/accelOp.png", "")
		images.Load("options/soundOp.png", "")
		images.Load("options/bigNote.png", "")
		
		images.Load("gameControl/arrows.png", "", False)
		images.Load("gameControl/ButtonA.png", "", False)
		images.Load("gameControl/ButtonB.png", "", False)
		
		images.LoadAnim("grade.png", 28, 28, 6, tmpImage)
		images.LoadAnim("plane.png", 50, 86, 7, tmpImage)
		images.LoadAnim("monster.png", 65, 65, 8, tmpImage)
		images.LoadAnim("monster2.png", 96, 98, 4, tmpImage)
		images.LoadAnim("fire.png", 44, 64, 5, tmpImage)
		images.LoadAnim("ball.png", 45, 58, 29, tmpImage)
		images.LoadAnim("paperBall.png", 65, 70, 11, tmpImage)
		images.LoadAnim("shot.png", 16, 16, 2, tmpImage)
		images.LoadAnim("explode.png", 64, 64, 10, tmpImage)
	End
	
	'summary: Load Sounds
	Method LoadSounds:Void()
		sounds.Load("shoot"+fmt)
		sounds.Load("hit"+fmt)
		sounds.Load("passed"+fmt)
		sounds.Load("paper"+fmt)
		sounds.Load("ink"+fmt)
		sounds.Load("heart"+fmt)
		sounds.Load("erase"+fmt)
		sounds.Load("ruler"+fmt)
		sounds.Load("shield"+fmt)
	End
End

Class Stone	'tokens
	Global list:ArrayList<Enemy> = New ArrayList<Enemy>
	Global enum:IEnumerator<Enemy> = list.Enumerator()
	Field position:Int
	Field progress:Int
	Field side:Int
	Method New(side:Int)
		Self.side = side
		progress = 0
		position = 0 * side * 16
		list.Add(Self)
	End
	Method Reset:Void()
		progress = 0
		position = 0 * side * 16
	End
	Method IsMovable:Bool(dice:Int)
		If progress = 0 And dice <> 6 Then Return False
		If progress + dice > 70 Then Return False
		If Game.doors
			'check if stone will pass a lucked door
		EndIf
		Return True
	End
	Method Move:Int(steps:Int)
		Local eats:Int = 0
		enum.Reset()
		While enum.HasNext()
			Local e:Stone = enum.NextObject()
			If e.position = position And e.side <> side And Not Game.SafeHouse(position)
				If Not (Game.teams And Abs(side - e.side) = 2)
					eats += 1
					e.Reset()
				EndIf
			EndIf
		End
		position += steps
		progress += steps
		Return eats
	End
End

Class Profile
	Field side:int
	Field stone:Stone[4]
	Field image:GameImage
	'stats
	Field eats:Int
	
	Method New()
		
	End
	Method GetProgress:Float()
		Local total:Int = 0
		For Local s:Stone = EachIn stone
			total += s.progress
		Next
		Return total / 70 / 4
	End
	Method GetEats:Float()
		
	End
	
	Method PrePlay:Void()
		Local dice:Int = Game.Roll_Dice()
		For Local s:Stone = EachIn stone
			If s.IsMovable(dice) Then s.move(dice)
		Next
	End
End

Class GameScreen Extends Screen
	Global teams:Bool
	Global doors:Bool
	Global difficulty:Int
	Field code:String	'for online multiplayers (host new game / join existing game or just watch 'side=0')
	Field privacy:Bool	'for online multiplayers (privacy=true means no watching without code)
	
	Method New()
		name = "Game"
	End
	Method Start:Void()
		game.screenFade.Start(100, False)
		'splash = game.images.Find("ma1ak")
	End
	Method Render:Void()
		
	End
	Method Update:Void()
		If Millisecs()>4000
'			If GetYear()>2012 Or GetMonth()>4
'				game.screenFade.Start(100, True, True, True)
'				game.nextScreen = demoScreen
'			Else
				game.screenFade.Start(100, True, True, True)
				game.nextScreen = titleScreen
'			End
		End
	End
	Function Roll_Dice:Int()
		Return Rnd(1, 6)
	End
	Function SafeHouse:Bool(position:Int)
		Local Safehouses:Int[] =[1, 13, 17, 29, 33, 45, 49, 61]
		For Local i:Int = EachIn Safehouse
			If position = i Then Return True
		Next
		Return False
	End
End


'summary: Ma1ak fadein nd fade out before the game start
Class SplashScreen Extends Screen
	Field splash:GameImage
	Method New()
		name = "Splash"
	End
	Method Start:Void()
		game.screenFade.Start(100, False)
		splash = game.images.Find("ma1ak")
	End
	
	Method Render:Void()
		DrawBG(splash.image)
	End
	
	Method Update:Void()
		If Millisecs()>4000
'			If GetYear()>2012 Or GetMonth()>4
'				game.screenFade.Start(100, True, True, True)
'				game.nextScreen = demoScreen
'			Else
				game.screenFade.Start(100, True, True, True)
				game.nextScreen = gameScreen
'			End
		End
	End
End

'summary: Demo Screen shows when demo version has expired (android only for now)
Class DemoScreen Extends Screen
	Field bg:GameImage
	Method New()
		name = "Demo is over"
	End
	Method Start:Void()
		game.screenFade.Start(100, False)
		bg = game.images.Find("titleBG")
	End
	
	Method Render:Void()
		DrawBG(bg.image)
		DrawText("Thank You",dW/2,dH*.1,.5)
		blackFont.DrawText("This version has expired,",dW*.15,dH*.3)
		blackFont.DrawText("Please visit the Android Market and install the latest version.",dW*.2,dH*.4)
		blackFont.DrawText("Thanks for your support and valued feedback.",dW*.2,dH*.5)
		blackFont.DrawText("Developer,",dW*.19,dH*.7)
		blackFont.DrawText("Aman Alshurafa",dW*.15+Rnd(-3,3),dH*.8)
	End
	
	Method Update:Void()
		If TouchHit() Or KeyHit(KEY_ESCAPE)
			game.screenFade.Start(50, True, True, True)
			game.nextScreen = game.exitScreen
		End
	End
End

'summary: Title screen (Main Menu)
Class TitleScreen Extends Screen

	Field shakeCnt : Int = 0
	Field shakeStart : Int
	'number of shakes to detect	
	Field shakeMax : Int = 4
	'time in millisecs that shake has to occur withing
	Field shakeTmr : Int = 2000
	'minimum velocity of the movement to detect
	Field shakeVel : Float = 1.5

	Field background:GameImage
	Field title:GameImage
	Field subtitle:GameImage
	Field hitSnd:GameSound
	Field classic:Button
	Field survival:Button
	
	Field msg:String
	
	Method New()
		name = "Title"
	End

	Method Start:Void()
		Local btn:GameImage=game.images.Find("classic")
		classic= New Button(btn,(dW-btn.w)/2)
		btn=game.images.Find("survival")
		survival= New Button(btn,(dW-btn.w)/2,dH*.7)
		game.screenFade.Start(50, False)
		Local touch:Bool
		#If TARGET="android" Or TARGET="ios"
			touch=True
		#Else
			touch=False
		#End
		'game.MusicPlay("Title"+fmt, True)
		#If TARGET="xna"
			PlayMusic("music/Title.mp3")
		#Else
			PlayMusic("music/Title"+fmt)
		#End
		hitSnd = game.sounds.Find("hit")
		background = game.images.Find("titleBG")
		title = game.images.Find("title")
		subtitle = game.images.Find("subtitle")
		game.MusicSetVolume(options.musicV)
	End
	
	Method Render:Void()
		DrawBG(background.image)
		DrawImage(game.images.Find("ruler").image,dW*.2,0,-45,1,1)
		Scale .5,.5
		DrawText "V"+version, dW, dH*1.95, 0.5, 0.5
		Scale 2,2
		Drop.DrawAll()
		DrawImage(game.images.Find("paperBall").image,dW*.15,dH*.17,3)
		classic.Draw()
		survival.Draw()
		DrawImage subtitle.image, dW*.65, dH*.25
		DrawImage title.image, dW*.5, dH*.35, Rnd(-1,1), 1, 1
		options.DrawSoundBox()
		options.Draw()
		DrawText(""+highscore,dW*.05,0)
	End

	Method Update:Void()
		#If TARGET<>"flash"
			ShakeCheck()
		#End
		options.Update()
		If Not options.shown
			If survival.Click() Or KeyHit(KEY_SPACE) Or JoyHit(JOY_B)
				game.screenFade.Start(50, True, True, True)
				Drop.list.Clear()
				level=1
				currentLvl= New Lvl(0,0,0)
				options.pause=False
				currentLvl.showSummary=False
				game.nextScreen = gameScreen
				score=0
			Elseif classic.Click() Or JoyHit(JOY_A)
				currentLvl= New Lvl(0,0,0)
				game.screenFade.Start(50, True, True)
				Drop.list.Clear()
				game.nextScreen = levelScreen
				'Story HERE
			Else
				For Local i% = 0 Until 10
					If TouchHit(i) And Touch_X(i)>65 And Not options.soundBox.Click() And Not options.musicBox.Click() And Not options.icon.Click()
						New Drop(game.images.Find("drop"),Touch_X(i),Touch_Y(i))
						If options.soundF
							hitSnd.Play()
						End
					End
				Next
			End
		End
		If KeyHit(KEY_ESCAPE)
			game.screenFade.Start(50, True, True, True)
			game.nextScreen = game.exitScreen
		End
	End
	
	' summary: If device is shaked, it will clear all drops from title screen
	Method ShakeCheck:Void()
		'if time has elapsed, reset timer and shake count
		If Millisecs() - shakeStart > shakeTmr
			Self.shakeCnt = 0
			Self.shakeStart = Millisecs()
		Endif
		
		'if accel has has been detected
		#If TARGET="android" Or TARGET="ios"
			If Abs( AccelH() ) > Self.shakeVel Or Abs( AccelW() ) > Self.shakeVel Or Abs( AccelZ() ) > Self.shakeVel
				
				'increment shake count
				Self.shakeCnt = Self.shakeCnt + 1
				
				'if shake count has reached required number
				If Self.shakeCnt > Self.shakeMax
				
					'reset the shake count and the timer
					Self.shakeCnt = 0
					Self.shakeStart = Millisecs()
	
					'do something
					Drop.list.Clear()
				End
			End
		#End
	End
End

'summary: Level selection screen
Class LevelScreen Extends Screen
	Field background:GameImage
	Field backHome:Button
	Field chBtn:Button[4]
	Field ch:Int=1
	Method New()
		name="Level Screen"
	End
	
	Method Start:Void()
		BackToCh()
		Local tmpImg:=game.images.Find("backHome")
		backHome= New Button(tmpImg,dW*.1,dH-tmpImg.h)
		chBtn[0]=New Button(dW*.9,0,dW*.1,dH*.3)
		chBtn[1]=New Button(dW*.9,dH*.3,dW*.1,dH*.2)
		chBtn[2]=New Button(dW*.9,dH*.5,dW*.1,dH*.2)
		chBtn[3]=New Button(dW*.9,dH*.7,dW*.1,dH*.3)
	End

	Method Render:Void()
		DrawBG(background.image)
		For Local i:Int=(ch-1)*15 To ((ch-1)*15)+14
			levels[i].Draw()
		End
		backHome.Draw()
	End
	
	Method Update:Void()
		If backHome.Click() Or KeyHit(KEY_ESCAPE)
			game.screenFade.Start(50, True, True, True)
			game.nextScreen = titleScreen
		End
		For Local i:Int=0 To 3
			If chBtn[i].Click()
				ch=i+1
				ChangeBG()
				Exit
			End
		End
		For Local i:Int=(ch-1)*15 To ((ch-1)*15)+14
			If levels[i].Click() And Not levels[i].locked
				If i Mod 5 = 0 Then
					game.screenFade.Start(50, True, True, True)
					StoryScreen.story=(Int(i/5))+1
					game.nextScreen= storyScreen
					Exit
				Else
					game.screenFade.Start(50, True, True, True)
					currentLvl= New Lvl(levels[i])
					game.nextScreen = gameScreen
					options.pause=False
					currentLvl.showSummary=False
					Exit
				Endif
			End
		End
	End
	
	Method BackToCh:Void()
		Local tmp:Float=Float(currentLvl.level)/15.0
		If  tmp<=1
			ch=1
		Elseif tmp<=2
			ch=2
		Elseif tmp<=3
			ch=3
		Elseif tmp<=4
			ch=4
		End
		ChangeBG()
	End
	
	Method ChangeBG:Void()
		background=game.images.Find("ch"+ch)
	End
End

'summary: Start screen shows a help menu
Class StartScreen Extends Screen
	Field background:GameImage
	Field skipBtn:Button
	Field menu:Bool
	Field msg1:String
	Field msg2:String
	Field msg3:String
	Field monster:Button
	Field paperBall:Button
	Field ruler:Button
	Field scissors:Button
	Field lives:Button
	Field inkwell:Button
	Field invisible:Button
	Field eraser:Button
	Method New()
		name="Tutorial Screen"
		menu=True
	End
	Method Start:Void()
		game.screenFade.Start(50, False, True)
		background = game.images.Find("bg")
		Local corner:= game.images.Find("page_corner")
		skipBtn = New Button(corner,dW-corner.w,dH-corner.h)
		monster = New Button(game.images.Find("monster"),dW*.2,dH*.06, True)
		paperBall = New Button(game.images.Find("paperBall"),dW*.4,dH*.2, True)
		ruler = New Button(game.images.Find("ruler"),dW*.6,dH*.35, True)
		scissors = New Button(game.images.Find("scissors"),dW*.2,dH*.35, True)
		lives = New Button(game.images.Find("lives"),dW*.8,dH*.5, True)
		inkwell = New Button(game.images.Find("inkwell"),dW*.4,dH*.65, True)
		invisible = New Button(game.images.Find("invisible"),dW*.2,dH*.8, True)
		eraser = New Button(game.images.Find("eraser"),dW*.5,dH*.9)
	End
	Method Render:Void()
		DrawBG(background.image)
		If menu
			DrawAll()
		Else
			DrawText(msg1,dW*.55,dH*.2,.5,0)
			DrawText(msg2,dW*.55,dH*.5,.5,0)
			DrawText(msg3,dW*.55,dH*.8,.5,0)
		End
	End
	
	' summary: Draw All icons to select from
	Method DrawAll:Void()
		blackFont.DrawText("Click on what you want to know more about",dW*.4,dH*.05)
		blackFont.DrawText("Click on corner of the page to skip this page",dW*.4,dH*.8)
		monster.Draw()
		paperBall.Draw()
		ruler.Draw()
		scissors.Draw()
		lives.Draw()
		inkwell.Draw()
		invisible.Draw()
		eraser.Draw()
		skipBtn.Draw()
	End
	
	Method Update:Void()
		If menu=True
			If monster.Click()
				game.screenFade.Start(50, False)
				msg1="These are only drawings,"
				msg2="they can't hit you,"
				msg3="but don't let them pass!"
				menu=False
			Elseif paperBall.Click()
				game.screenFade.Start(50, False)
				msg1="This is an obstacle."
				msg2="Don't hit it."
				msg3="just let go through."
				menu=False
			Elseif ruler.Click() Or scissors.Click()
				game.screenFade.Start(50, False)
				msg1="The last thing"
				msg2="you want to hit"
				msg3="is this"
				menu=False
			Elseif lives.Click()
				game.screenFade.Start(50, False)
				msg1="This will restore"
				msg2="your health."
				msg3=""
				menu=False
			Elseif inkwell.Click()
				game.screenFade.Start(50, False)
				msg1="This will refill"
				msg2="your pen with ink."
				msg3=""
				menu=False
			Elseif invisible.Click()
				game.screenFade.Start(50, False)
				msg1="This will protect you"
				msg2="from obstacles like"
				msg3="rulers and paper balls"
				menu=False
			Elseif eraser.Click()
				game.screenFade.Start(50, False)
				msg1="This will erase"
				msg2="about half of the"
				msg3="monsters in the Screen."
				menu=False
			Elseif skipBtn.Click()
				game.screenFade.Start(50, True, True, True)
				game.nextScreen = gameScreen
			End
		Elseif TouchHit()
			game.screenFade.Start(50, False)
			menu=True
		End
	End
End

'summary: This is where the fun start for you and pain start for me
Class GamScreen Extends Screen
	Field timeout:Bool
	Field bgY:Int			'Dy for background
	Field objects:Int
	Field seconds:Int		'timer +=1 every time update is called
	Field monsters:Int		'counter for the number of monsters to be unleashed before every level
	Field speed:Float
	Field background:GameImage
	Field player:Player
	Field lifeImage:GameImage
	Field shotImage:GameImage
	Field dropImage:GameImage
	Field livesImage:GameImage
	Field hitSnd:GameSound
	Field pasSnd:GameSound
	Field heartSnd:GameSound
	Field inkSnd:GameSound
	Field shieldSnd:GameSound
	Field rulerSnd:GameSound
	Field paperSnd:GameSound
	Field msg:String
	
	Method New()
		name = "Game Screen"
		level=1
		speed=.9
		seconds=1
		msg=""
		options.pause=False
	End

	Method Start:Void()
		level=1
		bgY=0
		Local gi:GameImage = game.images.Find("plane")
		background = game.images.Find("bg")
		hitSnd= game.sounds.Find("hit")
		pasSnd= game.sounds.Find("passed")
		heartSnd= game.sounds.Find("heart")
		inkSnd= game.sounds.Find("ink")
		shieldSnd= game.sounds.Find("shield")
		rulerSnd= game.sounds.Find("ruler")
		paperSnd= game.sounds.Find("paper")
		dropImage = game.images.Find("drop")
		livesImage = game.images.Find("lives")
		player = New Player(gi, SCREEN_WIDTH2, dH-gi.h/2, game.images.Find("shot"))
		StartLevel()
		'game.MusicPlay("Playing"+fmt, True)
		#If TARGET="xna"
			PlayMusic("music/Playing.mp3")
		#Else
			PlayMusic("music/Playing"+fmt)
		#End
		game.screenFade.Start(50, False, True, True)
		timeout=False
	End

	Method Render:Void()
		SetColor(255,255,255)
		If Not options.pause
			DrawMoveBG()
		End
		Drop.DrawAll()
		Enemy.DrawSome(e1)
		Enemy.DrawSome(e2)
		Enemy.DrawSome(f2)
		Enemy.DrawSome(f1)
		Enemy.DrawSome(h1)
		Enemy.DrawSome(i1)
		Bullet.DrawAll()
		Enemy.DrawSome(r1)
		Enemy.DrawSome(r2)
		Enemy.DrawSome(a1)
		If currentLvl.visiblePlane
			player.Draw()
		End
		Enemy.DrawSome(s1)
		Enemy.DrawSome(p1)
		Enemy.DrawSome(0)
		If currentLvl.visibility=1
			game.images.Find("fog").Draw(0,0)
		Elseif currentLvl.visibility=2
			SetColor(0,0,0)
			SetAlpha(.9)
			DrawRect(0,0,SCREEN_WIDTH,SCREEN_HEIGHT)
			SetAlpha(1)
			SetColor(255,255,255)
		Elseif currentLvl.visibility=3
			SetColor(0,0,0)
			If seconds Mod 100>10 Then DrawRect(0,0,SCREEN_WIDTH,SCREEN_HEIGHT)
			SetColor(255,255,255)
		Endif
		DrawGUI()
		If options.pause
			DrawPause()
		Else
			vc.Draw()
			options.pauseBtn.Draw()
		End
		If currentLvl.showSummary
			currentLvl.DrawSummary()
		End
		If options.pause
			options.Draw()
		End
	End
	
	'summary: Draw the animated backgound
	Method DrawMoveBG:Void()
		If bgY>dH
			bgY=0
		Else 
			bgY+=1
		End
		DrawImage background.image, 0, bgY, 0, dW/background.image.Width(), dH/background.image.Height()
		DrawImage background.image, 0, -dH+bgY, 0, dW/background.image.Width(), dH/background.image.Height()
	End
	
	'summary: Draw health meter, ink meter, and score inside the game
	Method DrawGUI:Void()
		DrawText msg,dW*.5,dH*.5,.5,.5
		If player.immunity>0 And player.immunity<200 And seconds Mod 10>1
			DrawImage(game.images.Find("invisible").image,dW*.9-1,dH*.1)
		End
		'ink meter
		If currentLvl.inkF
			SetColor(0,0,133)
			If player.ink>10 Or seconds Mod 10> 3
				If player.ink>0
					DrawRect(dW*.09,dH*.05+(200-player.ink*2),dW*.03-1,player.ink*2)
				End
				DrawRectOutline(dW*.09,dH*.05,dW*.03,200)
			End
		End
		'heart meter
		SetColor(255,0,0)
		If player.lives>10 Or seconds Mod 10> 3
			If player.lives>0
				DrawRect(dW*.05,dH*.05+(200-player.lives*2),dW*.03-1,player.lives*2)
			End
			DrawRectOutline(dW*.05,dH*.05,dW*.03,200)
		End
		SetColor(255,255,255)
		DrawText(""+score, dW*.05, 0)
	End
	
	'summary: Draw Pause screen
	Method DrawPause:Void()
		DrawRect(0,0,dW,dH)
		DrawText "PAUSE",dW*.5,dH*.5,.5,.5
		If currentLvl.level=0
			DrawText "LEVEL"+level,dW*.5,dH*.25,.5,0
		Else
			DrawText "LEVEL"+currentLvl.level,dW*.5,dH*.25,.5,0
		End
		DrawGUI()
		options.home.Draw()
		options.redo.Draw()
		vc.Draw()
		If Not currentLvl.showSummary
			options.pauseBtn.Draw()
		End
	End
	
	'summary: clean all list from data before starting a new level
	Method ClearLevel:Void()
		Enemy.list.Clear()
	End
	
	'summary: Start a new level and initiate values
	Method StartLevel:Void()
		If currentLvl.level=0
			monsters = level*10
			objects = level*2
			seconds=1
			ClearLevel()
			If level=1 Then speed=.9
			speed+=.1
		Else
			score=0
			level = currentLvl.level
			monsters = currentLvl.monsters
			objects = currentLvl.objects
			seconds=1
			ClearLevel()
			speed=currentLvl.speed
		End
	End
	
	'summary: Update level progress (when to make objects and when to declare winning or losing)
	Method UpdateLevel:Void()
		'create enemies
		Local giP1:GameImage = game.images.Find("paperBall")
		Local e:Enemy
		'inkwells
		If seconds Mod (4000/(((level-1) Mod 5)+1))=0 And monsters>0 And player.ink<100
			e = New Enemy(game.images.Find("inkwell"),player.x, -100,i1)
			e.dy = 1
			e.dx = 0
			e.movement = 1
			e.score = 30
			e.type=i1
		End
		'hearts
		If seconds Mod (3000/(((level-1) Mod 5)+1))=0 And monsters>0 And player.lives<100
			e = New Enemy(game.images.Find("lives"),player.x, -100,h1)
			e.dy = 1
			e.dx = 0
			e.movement = 1
			e.rotation=5*Rnd(-5,5)
			e.score = 5
			e.type=h1
		End
		'invisible shields
		If currentLvl.level>10
			If seconds Mod (8500/(((level-1) Mod 5)+1))=0 And monsters>0 And player.immunity=0
				e = New Enemy(game.images.Find("invisible"),player.x, -100,s1)
				e.dy = 1
				e.dx = 0
				e.movement = 1
				e.type=s1
			End
		End
		'enemy
		If (seconds Mod (200/(((level-1) Mod 5)+1))=0) And monsters>0
			e = New Enemy(currentLvl.enemyImg, Rnd(dW*.17,dW-currentLvl.enemyImg.w), -100,currentLvl.enemyType)
			e.dy = speed
			e.dx = 0
			e.movement = 1
			If currentLvl.enemyType=e1 Or currentLvl.enemyType=e2
				e.red=10*Rnd(0,25)
				e.green= 10*Rnd(0,25)
				e.blue= 10*Rnd(0,25)
				e.maxFrame = 7
				e.SetFrame(0, 7, 80, True)
				e.score = 100
				e.type=e1
			Elseif currentLvl.enemyType=f1
				e.maxFrame = 4
				e.SetFrame(0, 4, 40)
				e.score = 200
				e.type=f1
			Elseif currentLvl.enemyType=f2
				e.maxFrame = 28
				e.SetFrame(0, 28, 30)
				e.score = 200
				e.type=f2
			Elseif currentLvl.enemyType=a1
				e.dy = speed*3
				e.dx = Rnd(-1,1)
				e.type=a1
				e.score=100
			End
			monsters-=1
		End
		'paper ball
		If seconds Mod (1000/(((level-1) Mod 5)+1))=0 And objects>0
			e = New Enemy(giP1, Rnd(giP1.w*2,dW-giP1.w), -100,p1)
			e.frame = 0
			e.maxFrame = 10
			e.dy = speed*3
			e.dx = 0
			e.movement = 1
			e.SetFrame(0, 10, 80)
			e.score = 0
			e.type=p1
			objects-=1
		End
		'ruler
		If seconds Mod (2500/(((level-1) Mod 5)+1))=5 And objects>0
			If objects Mod 2 = 0
				Local gi:GameImage = game.images.Find("ruler")
				e = New Enemy(gi,Rnd(dW-gi.w,dW-gi.w/2)+gi.w/2, -gi.h/2,r1)
			Else
				Local gi:GameImage = game.images.Find("scissors")
				e = New Enemy(gi,Rnd(dW*.2,dW-gi.w), -gi.h/2,r1)
			End
			e.dy = speed*2
			e.dx = 0
			e.movement = 1
			e.score = 0
			e.type=r1
			objects-=1
		End
		seconds+=1
		
		CheckCollisions()
		If msg <> "" And seconds>200
			msg=""
		End
		If monsters=0 And Enemy.list.IsEmpty()
			msg="LEVEL "+level+" CLEARED!"
			seconds=1
			level+=1
			player.erasers+=1
			vc.eraser.name=""+player.erasers
			If currentLvl.level=0
				score+=10000
				StartLevel()
			Else
				Local div:Int=1
				If currentLvl.enemyType=f1
					div=2
				Elseif currentLvl.enemyType=f2
					div=3
				End
				'Grades
				If (score/levels[(currentLvl.level)-1].monsters)/div>=90 
					currentLvl.grade=1
				Elseif (score/levels[(currentLvl.level)-1].monsters)/div>=80 
					currentLvl.grade=2
				Elseif (score/levels[(currentLvl.level)-1].monsters)/div>=70 
					currentLvl.grade=3
				Else
					currentLvl.grade=4
				End
				If player.lives>=90
					currentLvl.grade+=.1
				End
				
				currentLvl.score=score
				If levels[currentLvl.level-1].score <=score
					levels[currentLvl.level-1].score=score
					
					If levels[currentLvl.level-1].grade-.1 >currentLvl.grade Or levels[currentLvl.level-1].grade=0
						levels[currentLvl.level-1].grade=currentLvl.grade
					End
					options.SaveInfo()
				End
				If currentLvl.level<>60
					levels[currentLvl.level].locked=False
				Else
					'congratulations
				End
				game.screenFade.Start(100, False, True, True)
				If game.screenFade.active
					options.pause=True
					currentLvl.showSummary=True
				End
			End
		End
		If player.lives<=0
			options.SaveInfo()
			game.screenFade.Start(100, True, True)
			If currentLvl.level=0
				gameOverScreen = New GameOverScreen()
				game.nextScreen = gameOverScreen
			Else
				options.pause=True
				currentLvl.showSummary=True
				levels[(currentLvl.level)-1].grade=5
			End
		End
	End
	
	'summary: Update everything in the game screen
	Method Update:Void()
		If Not currentLvl.showSummary
			options.TogglePause()
		End
		gameControl.Update
		vc.Update()
		If options.pause
			If KeyHit(KEY_ESCAPE) Or (options.home.Click() And Not options.shown)
				options.SaveInfo()
				game.screenFade.Start(50, True, True, True)
				game.nextScreen = titleScreen
				options.pauseBtn.img=game.images.Find("pause")
				Drop.list.Clear()
				Bullet.list.Clear()
				Enemy.list.Clear()
			Elseif options.redo.Click() And Not options.shown
				options.pause=False
				currentLvl.showSummary=False
				options.SaveInfo()
				game.screenFade.Start(50,True)
				game.nextScreen=gameScreen
				StartLevel()
				options.pauseBtn.img=game.images.Find("pause")
				Drop.list.Clear()
				Bullet.list.Clear()
				Enemy.list.Clear()
			Elseif currentLvl.showSummary And currentLvl.nextLevel.Click() And Not options.shown And currentLvl.level<60
				options.pause=False
				currentLvl.showSummary=False
				options.SaveInfo()
				If currentLvl.level Mod 5 = 0 Then
					game.screenFade.Start(50, True, True, True)
					StoryScreen.story=(Int(currentLvl.level/5))+1
					game.nextScreen= storyScreen
				Else
					If Not levels[currentLvl.level].locked
						currentLvl=New Lvl(levels[currentLvl.level])
					End
					game.screenFade.Start(50,True)
					game.nextScreen=gameScreen
					StartLevel()
				End
				options.pauseBtn.img=game.images.Find("pause")
				Drop.list.Clear()
				Bullet.list.Clear()
				Enemy.list.Clear()
			Elseif currentLvl.showSummary And currentLvl.levelMenu.Click() And Not options.shown
				options.pause=False
				currentLvl.showSummary=False
				options.SaveInfo()
				game.screenFade.Start(50,True)
				game.nextScreen=levelScreen
				levelScreen.Start()
				options.pauseBtn.img=game.images.Find("pause")
				Drop.list.Clear()
				Bullet.list.Clear()
				Enemy.list.Clear()
			End
		End
		If Not options.pause
			player.Update()
			UpdateLevel()
			Enemy.UpdateAll()
			Bullet.UpdateAll()
			Drop.UpdateAll()
		Else
			options.Update()
		End
		If options.pause
			msg=""
		End
	End

	'summary: Checks if bullets and player hitt objects
	Method CheckCollisions:Void()
		Local b:Bullet
		Local e:Enemy
		Local hit:Bool = False

		Enemy.enum.Reset()
		While Enemy.enum.HasNext()
			e = Enemy.enum.NextObject()
			If player.Collide(e)
				If e.type=p1 'Plane hits paper ball
					e.type=0
					If player.alpha=1
						player.lives-=5
						If options.soundF
							paperSnd.Play()
						End
					End
					e.dx=3*Rnd(-1,1)
					If e.dx=0
						e.dx=3
					End
				Elseif e.type=r1	'Plane hits ruler	'need to fix android audio bug  'Kinda fixed: need testers To check it out
					player.dy+=1
					If player.alpha=1
						player.lives-=1
						player.blink=50
						If options.soundF And seconds Mod 5 = 0
							rulerSnd.Play()
						End
					End
				Elseif e.type=i1	'Plane gets ink
					e.type=0
					player.ink+=e.score
					If options.soundF
						inkSnd.Play()
					End
					Enemy.enum.Remove()
				Elseif e.type=h1	'Plane gets health
					e.type=0
					player.lives+=e.score
					If options.soundF
						heartSnd.Play()
					End
					Enemy.enum.Remove()
				Elseif e.type=s1	'Plane gets shield
					e.type=0
					player.alpha=.3
					player.immunity=1000
					If options.soundF
						shieldSnd.Play()
					End
					Enemy.enum.Remove()
				Elseif e.type=f1
					e.type=0
					If player.alpha=1
						player.lives-=1
						'special fire effect on the plane
						player.blink=10
						If options.soundF
							'Fire sound
						End
					End
					Enemy.enum.Remove()
				Elseif e.type=f2
					e.type=0
					If player.alpha=1
						player.lives-=2
						Local explosion := New Drop(game.images.Find("explode"),e.x,e.y)
						explosion.type=f2
						explosion.alpha=1
						explosion.frame=0
						explosion.maxFrame=9
						explosion.SetFrame(0,9,80,False,False)
						'special fire effect on the plane
						player.blink=10
						If options.soundF
							'Fire sound
						End
					End
					Enemy.enum.Remove()
				Elseif e.type=a1
					e.type=0
					If player.alpha=1
						If e.x>player.x
							player.x-=dW*.05
						Else
							player.x+=dW*.05
						End
						player.blink=20
						player.lives-=5
						If options.soundF
							paperSnd.Play()
						End
					End
				End
			End
			Bullet.enum.Reset()
			While Bullet.enum.HasNext()
				b = Bullet.enum.NextObject()
				If b.Collide(e) And e.type >100  'below 100 are not enemies
					If options.soundF
						hitSnd.Play()
					End
					Bullet.enum.Remove()
					If e.type<200			'are not objects
						score+=e.score
						If score Mod 1000 = 0
							player.lives+=1
						End
						If e.type=e1 Or e.type=e2 Or e.type=f1
							'f1 fire turned off
							New Drop(dropImage,e.x,e.y)
							Enemy.enum.Remove()
							Exit
						Elseif e.type=f2
							e.type=f1
							Local explosion := New Drop(game.images.Find("explode"),e.x,e.y)
							explosion.type=f2
							explosion.alpha=1
							explosion.frame=0
							explosion.maxFrame=9
							explosion.SetFrame(0,9,80,False,False)
							If options.soundF
								'Fire sound
							End
							e.hide(45) '9 frames * 80 update rate / (millisec -> FPS) = hide for 45 frames
							e.image=game.images.Find("fire")
							e.maxFrame = 4
							e.SetFrame(0, 4, 40)
							e.score = 100
							Exit
						Elseif e.type=a1
							player.lives-=2
							player.blink=5
							Enemy.enum.Remove()
						End
					End
				End
			End
			If e.Passed()
				e.survive=True
				If e.type= e1 Or e.type= e2 Or e.type= f1
					player.lives-=1
					If options.soundF
						pasSnd.Play()
					End
				Elseif e.type=a1
					score+=e.score
				End
			End
		End
	End
End

Class StoryScreen Extends Screen
	Global story:Int
	Field skip:Button
	Field line1:Int,line2:Int
	Field background:GameImage
	Field stickman:GameImage
	Field textA1:String[][]=[
		["Hi, remember me?","You have drawn me in one of your classes","Your brother want to make you pay for what","He took his crayons and is looking for","Me, along with everything you wrote","Ok get a piece of paper, a pen,"],
		["Be careful not to use too much ink","Because, you could run out of ink.","Wait for an ink fountain to fill up"],
		["You probably noticed that you can fly over","But in some levels, there are obstacles","You're not as stupid as you look"],
		
		["This can be easy or hard depending on","Your brother will use every shot you miss","Then new monsters will keep coming at you"],
		["I only have 1 advice for the next 5 levels","Don't shoot!"],
		["Do you consider yourself a good pilot?","Let's see how do you do if you can't"],
		
		["Can you see through fog?","Play the next 5 levels and test"],
		["Are you afraid of the dark?","I just did"],
		["Are you afraid of the dark?","Cause more darkness is coming"],
		
		["Your brother is playing with fire now.","No, he is gonna burn your notes you clown","That's a no brainer.","Do not touch the fire flames,"],
		["Uh-oh, fire balls","Sometimes, I think burning into ashes is","If you shoot them, they will explode","Let them pass or shoot them twice"],
		["The next five levels are the same as","I don't think you can make it but"]]
	
	Field textA2:String[][]=[
		["","that you thought boring.","you did to his toys.","your notebook.","are in danger of being lost forever","and a tape."],
		["from now on.","","the pen with ink"],
		["the drawings without losing any points.","you need to avoid",""],
		
		["how you use your ink","and make a new monster out of it",""],
		["",""],
		["","see your plain"],
		
		["","how stupid my question is."],
		["",""],
		["",""],
		
		["","","","Do not let them pass!"],
		["","better than stucking with you for eternity","and produce fire flames.",""],
		["the previous ones but with obstacles","I would love to see you prove me wrong"]]
	Field textB:String[][]=[
		["...?","Yeah I remember you.","So what? Thatâ€™s not the first time.","WHAT!?","But I have finals and need to study","OK"],
		["Why?","What should I do when that happen?","OK"],
		["Yes, as long as they don't pass","But I can let them pass, right?","OK"],
		["What do you mean?","What if I keep missing?","OK"],
		["What is it?","OK"],
		["mmm, I think so","OK"],
		["That's a stupid question","OK"],
		["Don't till me it is gonna be dark!","OK"],
		["You asked me this question before!","OK"],
		["You're right he is.","What? That is dangerous.","How do I deal with fire?","OK"],
		["Fire Balls! COOL!! where are they?","What is it with fire balls then?","How can I take care of them?","OK"],
		["This should be easy.","OK"]]
	Global lvl:Int
	Method New()
		name = "Story Screen"
		story = 0
		line1 = 0
		line2 = 0
	End
	
	Method Start:Void()
		background = game.images.Find("bg")
		stickman = game.images.Find("stickman")
		skip= New Button(SCREEN_WIDTH*.8,SCREEN_HEIGHT*.92,150,38,"Skip")
		skip.click_effect=True
	End
	
	Method Render:Void()
		SetColor(255,255,255)
		DrawBG(background.image)
		stickman.Draw(SCREEN_WIDTH*.96,SCREEN_HEIGHT*.85,25)
		DrawRect(skip.x,skip.y,skip.w,skip.h)
		skip.Draw()
		SetColor(0,0,0)
		DrawRectOutline(skip.x,skip.y,skip.w,skip.h)
		SetColor(255,255,255)
		PushMatrix()
		Scale(1.5,1.5)
		If line1<>0
			blackFont.DrawText(textA1[story-1][line1-1],dW*.1,SCREEN_HEIGHT*0.05)
			blackFont.DrawText(textA2[story-1][line1-1],dW*.1,SCREEN_HEIGHT*0.15)
		End
		If line2<>0
			If textB[story-1][line2-1]<>"OK"
				blackFont.DrawText(textB[story-1][line2-1],dW*.1,SCREEN_HEIGHT*.55)
				PopMatrix()
			Else
				PopMatrix()
				Scale(2,2)
				DrawText("PLAY",SCREEN_WIDTH/4,SCREEN_HEIGHT/4,.5,.5)
				Scale(.5,.5)
			Endif
		Endif
	End
	
	Method Update:Void()
		If skip.Click()
			line1=0
			line2=0
			game.screenFade.Start(50, True, True, True)
			currentLvl= New Lvl(levels[((story-1)*5)])
			game.nextScreen = gameScreen
			options.pause=False
			currentLvl.showSummary=False
		Elseif TouchHit()
			If line2>0
				If textB[story-1][line2-1]="OK"
					line1=0
					line2=0
					game.screenFade.Start(50, True, True, True)
					currentLvl= New Lvl(levels[((story-1)*5)])
					game.nextScreen = gameScreen
					options.pause=False
					currentLvl.showSummary=False
				Else
					If line1=line2
						line1+=1
					Else
						line2+=1
					Endif
				Endif
			Elseif game.nextScreen <> gameScreen
				If line1=line2
					line1+=1
				Else
					line2+=1
				Endif
			End
		Endif
	End
End

'summary: Shows a game over screen with a customizable msg [b]For survival mode only[/b]
Class GameOverScreen Extends Screen
	Field msgR:String[10]
	Field footer:GameImage
	Field msg:String
	Field strech:Float
	Method New()
		name = "Game Over"
	End
	Method Start:Void()
		footer=game.images.Find("gameoverFooter")
		strech=dW/footer.image.Width()
		footer.image.SetHandle(0,0)
		
		game.screenFade.Start(25, False)
		
		msgR[0]="You can do better than that"						'1
		msgR[1]="You did good, harder luck next time"				'2
		msgR[2]="If this was a course, you would get a C"			'3
		msgR[3]="Who threw that paper plane?"						'4
		msgR[4]="You need someone to share their notes with you"	'5
		msgR[5]="Nice finger muscles, have you been playing?"		'6
		msgR[6]="The ruler has a crush on you"						'7
		msgR[7]="What kind of planes has a heart !!?"				'8
		msgR[8]="Try saving those notes if you wish to pass"		'9
		msgR[9]="Your doing great, keep trying"						'10
		If level>25
			msg="Not Perfect, but you got an A"
		Elseif level>20
			msg="Impressive! You my friend, rock"
'		ElseIf Player.ink=0
'			msg="Careful! ink is the new gold here"
		Elseif level>4
			msg="You did not pass, try harder next time"
		Elseif level=4
			msg="Not good enough ... try harder!"
		Elseif level=3
			msg="I think you need extra lessons"
		Elseif level=2
			msg="Really? is this the best you can do?"
		Elseif level=1
			msg="Are you sleeping or what?"
'		ElseIf Player.lives<-5
'			msg="Where did all of these objects come from?"
		Else
			msg=msgR[Rnd(9)]
		End
	End
	
	Method Render:Void()
		Cls
		DrawImage(footer.image,0,dH-footer.image.Height(),0,strech,strech)
		
		Scale 2,2
		DrawText "GAMEOVER", dW*.25, dH*.25,.5,.5
		Scale .5,.5
		DrawText "LEVEL: "+level, dW*.05, dH*.05
		DrawText "SCORE: "+score, dW*.05, dH*.15
		SetAlpha(.7)
		whiteFont.DrawText(msg,10,dH*.7)
	End

	Method Update:Void()
		If KeyHit(KEY_ESCAPE) Or KeyHit(KEY_SPACE) Or TouchHit(0)
			Drop.list.Clear()
			game.screenFade.Start(50, True, True, True)
			game.nextScreen = titleScreen
		End
	End
End

Class Player Extends Sprite
	Field erasers:Int
	Field blink:Int
	Field immunity:Int
	Field defaultAx:Float
	Field ink:Int
	Field lives:Int
	Field frameDelay:Int
	Field maxFrameDelay:Int = 3
	Field shotImage:GameImage
	Field shootSnd:GameSound
	Field eraseSnd:GameSound
	
	Method New(img:GameImage, x#, y#, shotImage:GameImage)
		Super.New(img, x, y)
		defaultAx=0
		ink = 100
		lives = 100
		immunity=0
		erasers=10
		vc.eraser.name=""+erasers
		blink=0
		frame = 3
		speedX = 1
		speedY = 1
		maxXSpeed = 5
		Self.maxYSpeed = 5
		Self.shotImage = shotImage
		shootSnd = game.sounds.Find("shoot")
		eraseSnd= game.sounds.Find("erase")
	End
	
	Method Erase:Void()
		If erasers>0
			score+= Enemy.RemoveType(e1,f2)*50
			If options.soundF
				eraseSnd.Play()
			End
			erasers-=1
			vc.eraser.name=""+erasers
		End
	End
	
	Method Update:Void()
		red=155+lives
		green=155+lives
		blue=155+lives
		If immunity>0
			immunity-=1
		Elseif immunity=0 And Self.alpha<>1
			Self.alpha=1
		End
		If blink>0
			blink-=1
			Self.rotation=Rnd(-10,10)
			Self.blue=10*Rnd(0,25)
			Self.green=Self.blue
			StartVibrate(50)
		Elseif blink=0 And Self.rotation<>0
			Self.rotation=0
			Self.red=255
			Self.blue=255
			Self.green=255
			StopVibrate()
		End
		If ink>100
			ink=100
		End
		If lives>100
			lives=100
		End
		If gameControl.GoLeft()
			Self.dx-=Self.speedX
			RollLeft()
		Elseif gameControl.GoRight()
			Self.dx+=Self.speedX
			RollRight()
		Else
			SlowShip(True)
		End
		If gameControl.GoUp()
			Self.dy-=Self.speedY
		Elseif gameControl.GoDown()
			Self.dy+=Self.speedY
		Else
			SlowShip(False)
		End
		If gameControl.Erase()
			Erase()
		Elseif gameControl.Shoot() And ink>0
			New Bullet(shotImage, x, y)
			If currentLvl.inkF
				ink-=1
			End
			If options.soundF
				shootSnd.Play()
			End
		End
		If dx > Self.maxXSpeed
			dx = Self.maxXSpeed
		End
		If dx < -Self.maxXSpeed
			dx = -Self.maxXSpeed
		End
		If dy > Self.maxYSpeed
			dy = Self.maxYSpeed
		End
		If dy < -Self.maxYSpeed
			dy = -Self.maxYSpeed
		End
		Self.Move()
		' limit the player to the screen
		If x < dW*.17
			x = dW*.17
		End
		If x > SCREEN_WIDTH - image.w2
			x = SCREEN_WIDTH - image.w2
		End
		If y < Self.image.h
			y = Self.image.h
		End
		If y > dH-Self.image.h/2
			y = dH-Self.image.h/2
		End
	End
	
	Method RollLeft:Void()
		If frame > 0
			frameDelay+=1
			If frameDelay > maxFrameDelay
				frame-=1
				frameDelay = 0
			End
		End
	End
	
	Method RollRight:Void()
		If frame < 6
			frameDelay+=1
			If frameDelay > maxFrameDelay
				frame+=1
				frameDelay = 0
			End
		End
	End

	Method SlowShip:Void(horizantal:Bool)
		If horizantal
			If frame < 3
				frameDelay+=1
				If frameDelay > maxFrameDelay
					frame+=1
					frameDelay = 0
				End
			Else If frame > 3
				frameDelay+=1
				If frameDelay > maxFrameDelay
					frame-=1
					frameDelay = 0
				End			
			End
			If dx > 0
				dx-=Self.speedX/4
			Else If dx < 0
				dx+=Self.speedX/4
			End
		Else
			If dy > 0
				dy-=Self.speedY/4
			Else If dy < 0
				dy+=Self.speedY/4
			End
		End
	End
End

Class Enemy Extends Sprite
	Global list:ArrayList<Enemy> = New ArrayList<Enemy>
	Global enum:IEnumerator<Enemy> = list.Enumerator()
	Field erase:Bool
	Field movement:Int
	Field moveCounter:Float
	Field type:Int
	Field score:Int
	Field survive:Bool
	Field hideT:Int=0
	
	Method New(img:GameImage, x#, y#, type:Int)
		Super.New(img, x, y)
		Self.frame = 0
		survive=False
		Self.dy = Rnd(1, 3)
		list.Add(Self)
	End
	
	Function UpdateAll:Void()
		enum.Reset()
		While enum.HasNext()
			Local e:Enemy = enum.NextObject()
			e.Update()
			If e.OutOfBounds() Then enum.Remove()
		End
	End
	
	Method Update:Void()
		If hideT>0
			alpha=0
			hideT-=1
		Elseif alpha<>1
			alpha=1
		End
		If type=s1
			Self.rotation+=1
		End
		UpdateAnimation()
		Move()
	End
	
	'summary: Make sprite hide for a limited [b]time[/b]
	Method hide:Void(time:Int)
		hideT=time
	End
	
	Method Passed:Bool()
		If y > SCREEN_HEIGHT And Not survive
			Return True
		End
		Return False
	End
	
	Method OutOfBounds:Bool()
		Return y > SCREEN_HEIGHT + image.h
	End
	
	Function DrawAll:Void()
		For Local i% = 0 Until list.Size
			Local e:Enemy = list.Get(i)
			e.Draw()
		Next
	End
	
	Function DrawSome:Void(type:Int)
		For Local i% = 0 Until list.Size
			Local e:Enemy = list.Get(i)
			If e.type=type
				e.Draw()
			End
		Next
	End
	
	Function RemoveType:Int(type:Int)
		Local count%=0
		For Local i% = 0 Until list.Size
			Local e:Enemy = list.Get(i)
			If e.type=type
				list.RemoveAt(i)
				count+=1
			End
		Next
		Return count
	End
	
	Function RemoveType:Int(type1:Int, type2:Int)
		Local count%=0
		For Local i% = 0 Until list.Size
			Local e:Enemy = list.Get(i)
			If e.type>=type1 And e.type<=type2
				list.RemoveAt(i)
				count+=1
			End
		Next
		Return count
	End
End

Class Bullet Extends Sprite
	Global list:ArrayList<Bullet> = New ArrayList<Bullet>
	Global enum:IEnumerator<Bullet> = list.Enumerator()
	
	Method New(img:GameImage, x#, y#)
		Super.New(img, x, y)
		Self.speedY = -6
		Self.frame = 0
		Self.maxFrame = 1
		Self.SetFrame(0, 1, 40)
		list.Add(Self)
	End
	
	Function UpdateAll:Void()
		enum.Reset()
		While enum.HasNext()
			Local b:Bullet = enum.NextObject()
			b.Update()
			If b.OutOfBounds()
				If currentLvl.enemyType=e2
					Local e := New Enemy(game.images.Find("monster2"), b.x, -100,currentLvl.enemyType)
					e.maxFrame = 3
					e.SetFrame(0, 3, 80)
					e.score = 100
					e.type=e2
				End
				enum.Remove()
			End
		End
	End
	
	Method Update:Void()
		Self.UpdateAnimation()
		dy = Self.speedY
		Move()
	End
	
	Method OutOfBounds:Bool()
		Return y < -image.h
	End
	
	Function DrawAll:Void()
		For Local i% = 0 Until list.Size
			Local b:Bullet = list.Get(i)
			b.Draw()
		Next		
	End
	
End

Class Drop Extends Sprite
	Field type:Int
	Global list:ArrayList<Drop> = New ArrayList<Drop>
	Global enum:IEnumerator<Drop> = list.Enumerator()
	
	Method New(img:GameImage, x#, y#)
		Super.New(img, x, y)
		Self.dy=1
		Self.alpha = .5
		Self.blue = Rnd(0,255)
		Self.rotation=30*Rnd(0,12)
		type=0
		list.Add(Self)
	End
	
	Function UpdateAll:Void()
		enum.Reset()
		While enum.HasNext()
			Local b:Drop = enum.NextObject()
			b.Update()
			If b.OutOfBounds() Then enum.Remove()
		End
	End
	
	Method Update:Void()
		Self.UpdateAnimation()
		Move()
	End
	
	Method OutOfBounds:Bool()
		If type=0
			Return y > dH+image.h
		Else
			If Self.frame=Self.maxFrame
				Return True
			End
		End
		Return False
	End
	
	Function DrawAll:Void()
		For Local i% = 0 Until list.Size
			Local b:Drop = list.Get(i)
			b.Draw()
		Next		
	End
End

Class Options
	Field seconds:Int
	Field touch:Int			'iPhone or Android
	Field controlType:Int	'keyboard, tilt, virtual controller
	Field page:Int			'main option page=0, sensevity page=1, sound page=2
	Field rotate:Float		'options icon rotation
	
	Field xTemp:Float
	Field yTemp:Float
	Field sensitivityTemp:Float
	Field musicVTemp:Float
	Field soundVTemp:Float
		
	Field musicV:Float
	Field soundV:Float
	Field musicF:Bool
	Field soundF:Bool
	Field pause:Bool
	Field shown:Bool
	Field pauseBtn:Button
	Field soundBox:Button
	Field musicBox:Button
	
	'Page 1
	Field reset:Button
	Field calibrate:Button
	Field default0:Button
	'page 2
	Field soundUp:Button
	Field soundDown:Button
	
	'Page 1&2
	Field senseUp:Button
	Field senseDown:Button
	Field saveBtn:Button
	Field ignoreBtn:Button
	Field icon:Button
	
	Field home:Button
	Field redo:Button
	
	Field circle:Sprite
	Field normal:Sprite
	Field virtual:Sprite
	Field accel:Sprite
	Field snd:Sprite
	Field bg1:Sprite
	Field bg2:Sprite
	
	Method New()
		shown=False
		pause=False
		soundF=True
		musicF=True
		musicV=25
		soundV=1
		rotate=1
		page=0
		xTemp=gameControl.x
		yTemp=gameControl.y
	End
	
	Method Start:Void()
		seconds=0
		If score>highscore
				highscore=score
		End
		score=0
		pauseBtn = New Button(game.images.Find("pause"),dW*.045,dH*.47)
		If soundF
			soundBox=New Button(game.images.Find("soundOn"),dW-game.images.Find("soundOn").w,-15)
		Else
			soundBox=New Button(game.images.Find("soundOff"),dW-game.images.Find("soundOff").w,-15)
		End
		If musicF
			musicBox=New Button(game.images.Find("musicOn"),soundBox.x,soundBox.img.h-15)
		Else
			musicBox=New Button(game.images.Find("musicOff"),soundBox.x,soundBox.img.h-15)
		End
		icon= New Button(game.images.Find("options"),dW*.1,dH*.25)
		home=New Button(game.images.Find("home"),dW*.52,dH*.8)
		redo=New Button(game.images.Find("redo"),dW*.49-home.w,dH*.8)
		
		bg1 = New Sprite(game.images.Find("bigNote"),dW*.221,dH-dH*.021)
		bg2 = New Sprite(game.images.Find("bigNote"),dW*.2,dH)

		senseUp=New Button(game.images.Find("incBtn"),dW*.221+bg1.image.w*.74,dH-bg1.image.h*.95)
		senseDown=New Button(game.images.Find("decBtn"),dW*.25,dH-bg1.image.h*.95)
		soundUp=New Button(game.images.Find("incBtn"),dW*.23+bg1.image.w*.74,dH-bg1.image.h*.55)
		soundDown=New Button(game.images.Find("decBtn"),dW*.27,dH-bg1.image.h*.55)
		default0=New Button(game.images.Find("default"),dW*.26,dH-bg1.image.h*.65)
		reset=New Button(game.images.Find("reset"),dW*.44,dH-bg1.image.h*.25)
		calibrate=New Button(game.images.Find("calibrate"),dW*.2+bg1.image.w*.73,dH-bg1.image.h*.65)
		ignoreBtn=New Button(game.images.Find("ignore"),dW*.3,dH-bg1.image.h*.3)
		saveBtn=New Button(game.images.Find("save"),dW*.25+bg1.image.w*.74,dH-bg1.image.h*.3)
		#If TARGET<>"android" And TARGET<>"ios"
			touch = 0
			#If TARGET="xna"
				If GetTarget()="XNA"
					touch = 3
				Elseif GetTarget()="Windows Phone"
					touch = 2
				Endif
			#End
			normal = New Sprite(game.images.Find("keyboardOp"),bg2.x*1.5,bg2.y-bg2.image.h*.8)
		#Else
			touch = 1
			normal = New Sprite(game.images.Find("tiltOp"),bg2.x*1.5,bg2.y-bg2.image.h*.8)
		#End
		controlType=touch
		virtual = New Sprite(game.images.Find("virtualOp"),normal.x+3,normal.y+normal.image.h+5)
		circle = New Sprite(game.images.Find("circle"),normal.x,normal.y)
		accel = New Sprite(game.images.Find("accelOp"),virtual.x,virtual.y+virtual.image.h*3)
		snd = New Sprite(game.images.Find("soundOp"),accel.x+virtual.image.h/2,accel.y+accel.image.h*3)
		
		'set handle
		circle.image.image.SetHandle(0,circle.image.h)
		normal.image.image.SetHandle(0,normal.image.h)
		virtual.image.image.SetHandle(0,virtual.image.h)
		accel.image.image.SetHandle(0,accel.image.h)
		snd.image.image.SetHandle(0,accel.image.h)
		bg1.image.image.SetHandle(0,bg1.image.h)
		bg2.image.image.SetHandle(0,bg2.image.h)
		bg1.dx=0
		bg1.dy=0
		bg2.dx=0
		bg2.dy=0
		
		bg2.x=dW*.2
		 
		'set rotation
		normal.rotation=6
		virtual.rotation=6
		accel.rotation=6
		snd.rotation=6
	End
	
	Method Draw:Void()
		icon.Draw()
		DrawSoundBox()
		If shown
			bg1.Draw()
			If page=1
				DrawPage1()
			Elseif page=2
				DrawPage2()
			End
			bg2.Draw()
			#If TARGET<>"xna"
				normal.Draw()
				virtual.Draw()
				circle.Draw()
			#EndIf
			accel.Draw()
			snd.Draw()
		End
	End
	
	Method DrawPage1:Void()
		blackFont.DrawText("Sensitivity: "+Int(sensitivityTemp*100),bg1.x*1.5,dH-bg1.image.h*.9)
		senseUp.Draw()
		senseDown.Draw()
		reset.Draw()
		default0.Draw()
		saveBtn.Draw()
		ignoreBtn.Draw()
		If touch=1
			SetColor(0,0,0)
			DrawLine(bg1.x*1.4,dH*.65,bg1.x*.6+bg1.image.w,dH*.65)
			DrawLine(bg1.x+bg1.image.w/2,dH-bg1.image.h*.8,bg1.x+bg1.image.w/2,dH-bg1.image.h*.2)
			DrawCircle(bg1.x+bg1.image.w/2,dH*.65,5)
			SetColor(255,0,0)
			#If TARGET<>"flash"
				DrawCircle(bg1.x+bg1.image.w/2-yTemp*100+AccelW()*100,dH*.65-xTemp*100+AccelH()*100,5)
			#End
			SetColor(255,255,255)
			calibrate.Draw()
		End
	End
	
	Method DrawPage2:Void()
		blackFont.DrawText("Music: "+Int(musicVTemp),bg1.x*1.7,dH-bg1.image.h*.9)
		senseUp.Draw()
		senseDown.Draw()
		
		blackFont.DrawText("Sounds: "+Int(soundVTemp*100),bg1.x*1.7,dH-bg1.image.h*.5)
		soundUp.Draw()
		soundDown.Draw()
		reset.Draw()
		saveBtn.Draw()
		ignoreBtn.Draw()
	End
	
	Method DrawSoundBox:Void()
		soundBox.Draw()
		musicBox.Draw()
	End
	
	Method Update:Void()
		seconds+=1
		UpdateSoundBox()
		ToggleMenu()
		If shown
			ToggleVirtual()
			TogglePage()
			If ignoreBtn.Click()
				page=0
			End
			If page=1
				UpdatePage1()
			Elseif page=2
				UpdatePage2()
			End
		End
		
		'The Options icon bounce back and forth
		If icon.rotation>5
			rotate=-.5
		Elseif icon.rotation<-5
			rotate=.5
		End
		icon.rotation+=rotate
		
		'page 0 slide back
		If page=0 And bg2.x<>dW*.2
			bg2.x+=6
			bg2.y-=3
			normal.x+=6
			normal.y-=3
			virtual.x+=6
			virtual.y-=3
			accel.x+=6
			accel.y-=3
			snd.x+=6
			snd.y-=3
			circle.x+=6
			circle.y-=3
		End
		
		'Page 0 slide out
		If page<>0 And bg2.x >0-bg2.image.h
			bg2.x-=6
			bg2.y+=3
			normal.x-=6
			normal.y+=3
			virtual.x-=6
			virtual.y+=3
			accel.x-=6
			accel.y+=3
			snd.x-=6
			snd.y+=3
			circle.x-=6
			circle.y+=3
		End
	End
	
	Method UpdatePage1:Void()
		If senseUp.Click() Or (senseUp.Down() And seconds Mod 10=0)
			sensitivityTemp+=.01
		Elseif senseDown.Click() Or (senseDown.Down()  And seconds Mod 10=0)
			sensitivityTemp-=.01
		End
		If reset.Click() Or ignoreBtn.Click()
			sensitivityTemp=gameControl.sensitivity
			If touch
				yTemp=gameControl.y
				xTemp=gameControl.x
			End
		Elseif default0.Click()
			sensitivityTemp=0.05
			#If TARGET="ios"
				xTemp=.4
			#Else
				xTemp=-.4
			#End
			yTemp=0
		#If TARGET<>"flash"
		Elseif calibrate.Click() And touch
			yTemp=AccelW()
			xTemp=AccelH()
		#End
		Elseif saveBtn.Click()
			page=0
			gameControl.sensitivity=sensitivityTemp
			If touch
				gameControl.y=yTemp
				gameControl.x=xTemp
			End
			SaveInfo()
		End
	End
	
	Method UpdatePage2:Void()
		If senseUp.Click() Or (senseUp.Down()  And seconds Mod 10=0)
			If musicVTemp<100
				musicVTemp+=1
			End
		Elseif senseDown.Click() Or (senseDown.Down()  And seconds Mod 10=0)
			If musicVTemp>0
				musicVTemp-=1
			End
		Elseif soundUp.Click() Or (soundUp.Down()  And seconds Mod 10=0)
			If soundVTemp<1
				soundVTemp+=.01
			End
		Elseif soundDown.Click() Or (soundDown.Down()  And seconds Mod 10=0)
			If soundVTemp>0
				soundVTemp-=.01
			End
		End
		If reset.Click() Or ignoreBtn.Click()
			musicVTemp=musicV
			soundVTemp=soundV
		Elseif saveBtn.Click()
			page=0
			musicV=musicVTemp
			soundV=soundVTemp
			For Local i%=0 Until 31
				SetChannelVolume(i,soundV)
			Next
			SaveInfo()
		End
	End
	
	Method UpdateSoundBox:Void()
		soundBox.Check()
		musicBox.Check()
		If soundBox.checked
			soundBox.img=game.images.Find("soundOff")
			soundF=False
			For Local i%=0 Until 31
				SetChannelVolume(i,0)
			Next
		Else
			soundBox.img=game.images.Find("soundOn")
			soundF=True
			For Local i%=0 Until 31
				SetChannelVolume(i,soundV)
			Next
		End
		If musicBox.checked
			musicBox.img=game.images.Find("musicOff")
			musicF=False
			game.MusicSetVolume(0)
		Else
			musicBox.img=game.images.Find("musicOn")
			musicF=True
			game.MusicSetVolume(musicV)
		End
	End
	
	Method TogglePause:Void()
		If pauseBtn.Click() Or KeyHit(KEY_ESCAPE)
			If pause
				SaveInfo()
				pauseBtn.img = game.images.Find("pause")
				pause=False
				musicF=False
			Else
				pauseBtn.img = game.images.Find("resume")
				pause=True
				musicF=True
			End
		End
	End
	Method ToggleMenu:Void()
		If icon.Click()
			If Not shown
				shown=True
				page=0
			Else
				shown=False
			End
		End
	End
	Method ToggleVirtual:Void()
		#If TARGET<>"XNA"
			If TouchHit() And Touch_X()>normal.x And Touch_X()<normal.x+normal.image.w And
			Touch_Y() > normal.y - normal.hitBox.h * 2 And Touch_Y() < normal.y - normal.hitBox.h * 0.5 + normal.image.h * 2
				circle.x=normal.x
				circle.y=normal.y
				If vc.show
					controlType = touch
					vc.show=False
				End
			End
			If TouchHit() And Touch_X()>virtual.x And Touch_X()<virtual.x+virtual.image.w And
			Touch_Y() > virtual.y - virtual.hitBox.h * 2 And Touch_Y() < virtual.y - virtual.hitBox.h * 0.5 + virtual.image.h * 2
				circle.x=virtual.x
				circle.y=virtual.y
				If Not vc.show
					controlType = 2
					vc.show=True
				End
			End
		#EndIf
	End
	Method TogglePage:Void()
		If TouchHit() And Touch_X()>accel.x And Touch_X()<accel.x+accel.image.w And
		Touch_Y() > accel.y - accel.hitBox.h * 2 And Touch_Y() < accel.y - accel.hitBox.h * 0.5 + accel.image.h * 2
			sensitivityTemp=gameControl.sensitivity
			page=1
		End
		If TouchHit() And Touch_X()>snd.x And Touch_X()<snd.x+snd.image.w And
		Touch_Y()>snd.y-snd.hitBox.h*2 And Touch_Y()<snd.y-snd.hitBox.h*.5+snd.image.h*2
			musicVTemp=musicV
			soundVTemp=soundV
			page=2
		End
	End
	Method SaveInfo:Void()
		Local str:String
		
		If score>highscore
			highscore=score
		End
		str= version+" "+level+" "+highscore+" "+soundV+" "+musicV+" "+gameControl.x+" "+gameControl.y+" "+gameControl.sensitivity+" "+Int(soundF)+" "+Int(musicF)
		For Local count:Int=0 To 59
			str+=" "+levels[count].score+"/"+levels[count].grade
		Next
		SaveState(str)
	End
End

Class VirtualController
	Field show:Bool
	Field arrows:Sprite
	Field btnA:Sprite
	Field btnB:Sprite
	Field eraser:Sprite
	Field eraserBig:Button 'Virtual Button for erase when virtual controller is not working
	
	Method New()
		show=False
		arrows=New Sprite(game.images.Find("arrows"),0,dH)
		arrows.y-=arrows.image.h
		arrows.alpha=.5
		btnA=New Sprite(game.images.Find("ButtonA"),dW,dH)
		btnA.x-=btnA.image.w
		btnA.y-=btnA.image.h
		btnA.alpha=.5
		btnB=New Sprite(game.images.Find("ButtonB"),dW,btnA.y)
		btnB.x-=btnB.image.w
		btnB.y-=btnB.image.h
		btnB.alpha=.5
		eraser=New Sprite(game.images.Find("eraser"),btnB.x+5,btnB.y+10)
		eraser.scaleX=.5
		eraser.scaleY=.5
		eraser.alpha=.5
		eraserBig= New Button(game.images.Find("eraser"),dW*.05,dH-40)
	End
	
	Method Draw:Void()
		If show
			arrows.Draw()
			btnA.Draw()
			btnB.Draw()
			eraser.Draw()
			DrawText(eraser.name,btnB.x+btnB.image.w/2,btnB.y+btnB.image.h/2,.5,.5) 'eraser name = number of erasers
		Else
			eraserBig.Draw()
			DrawText(eraser.name,eraserBig.x+eraserBig.img.w/2,eraserBig.y,.5,.5) 'eraser name = number of erasers
		End
	End
	
	Method Update:Void()
		If ButtonA()
			btnA.alpha=1
		Else
			btnA.alpha=.5
		End
		If ButtonB()
			btnB.alpha=1
		Else
			btnB.alpha=.5
		End
		If Arrows()
			arrows.alpha=1
		Else
			arrows.alpha=.5
		End
	End
	
	Method ButtonA:Bool()
		If (TouchDown(0) And Touch_X(0)>btnA.x And Touch_Y(0)>btnA.y) Or (TouchDown(1) And Touch_X(1)>btnA.x And Touch_Y(1)>btnA.y)
			Return True
		Else
			Return False
		End
	End
	
	Method ButtonB:Bool()
		If (TouchDown(0) And Touch_X(0)>btnB.x And Touch_Y(0)>btnB.y And Touch_Y(0)<btnA.y) Or
		(TouchDown(1) And Touch_X(1)>btnB.x And Touch_Y(1)>btnB.y And Touch_Y(1)<btnA.y)
			Return True
		Else
			Return False
		End
	End
	
	Method Arrows:Bool()
		If (TouchDown(0) And Touch_X(0)<arrows.image.w And Touch_Y(0)>arrows.y) Or (TouchDown(1) And Touch_X(1)<arrows.image.w And Touch_Y(1)>arrows.y)
			Return True
		Else
			Return False
		End
	End
	
	Method Shoot:Bool()
		If (TouchHit(0) And Touch_X(0)>btnA.x And Touch_Y(0)>btnA.y) Or (TouchHit(1) And Touch_X(1)>btnA.x And Touch_Y(1)>btnA.y)
			Return True
		Else
			Return False
		End
	End
	
	Method Erase:Bool()
		If (TouchHit(0) And Touch_X(0)>btnB.x And Touch_Y(0)>btnB.y And Touch_Y(0)<btnA.y) Or
		(TouchHit(1) And Touch_X(1)>btnB.x And Touch_Y(1)>btnB.y And Touch_Y(1)<btnA.y)
			Return True
		Else
			Return False
		End
	End
	
	Method MoveRight:Bool()
		If (TouchDown(0) And Touch_X(0)<arrows.image.w*1.3 And Touch_X(0)>arrows.image.w*2/3 And Touch_Y(0)>arrows.y) Or
		(TouchDown(1) And Touch_X(1)<arrows.image.w*1.3 And Touch_X(1)>arrows.image.w*2/3 And Touch_Y(1)>arrows.y)
			Return True
		Else
			Return False
		End
	End
	
	Method MoveLeft:Bool()
		If (TouchDown(0) And Touch_X(0)<arrows.image.w/3 And Touch_Y(0)>arrows.y) Or
		(TouchDown(1) And Touch_X(1)<arrows.image.w/3 And Touch_Y(1)>arrows.y)
			Return True
		Else
			Return False
		End
	End
	
	Method MoveDown:Bool()
		If (TouchDown(0) And Touch_X(0)<arrows.image.w And Touch_Y(0)>arrows.y+arrows.image.h/3) Or
		(TouchDown(1) And Touch_X(1)<arrows.image.w And Touch_Y(1)>arrows.y+arrows.image.h/3)
			Return True
		Else
			Return False
		End
	End
	
	Method MoveUp:Bool()
		If (TouchDown(0) And Touch_X(0)<arrows.image.w*1.3 And Touch_Y(0)>arrows.y And Touch_Y(0)<arrows.y+arrows.image.h2/3) Or
		(TouchDown(1) And Touch_X(1)<arrows.image.w*1.3 And Touch_Y(1)>arrows.y And Touch_Y(1)<arrows.y+arrows.image.h2/3)
			Return True
		Else
			Return False
		End
	End
End

Class GameControl
	Const touch:Int = 1
	Const keyboard:Int=0
	Const virtual:Int =2
	Const joystick:Int =3
	Field type:Int
	Field x:Float
	Field y:Float
	Field sensitivity:Float
	Method New()
		
	End
	Method Start:Void()
		sensitivity=0.05
		#If TARGET="ios"
			x=.4
		#Else
			x=-.4
		#End
		y=0
	End
	Method Update:Void()
		type=options.controlType
	End
	Method GoRight:Bool()
		#If TARGET="XNA"
			If JoyDown(JOY_RIGHT) Or KeyDown(KEY_RIGHT) Or KeyDown(KEY_D)
				Return True
			Endif
		#EndIf
		If type=keyboard
			If KeyDown(KEY_RIGHT) Or KeyDown(KEY_D)
				Return True
			Else
				Return False
			End
		Elseif type=virtual
			If vc.MoveRight()
				Return True
			Else
				Return False
			End
#If TARGET<>"flash"
		Elseif type=touch
			If AccelW()>y+sensitivity
				Return True
			Else
				Return False
			End
#End
		End
		Return False
	End
	Method GoLeft:Bool()
		#If TARGET="XNA"
			If JoyDown(JOY_LEFT) Or KeyDown(KEY_LEFT) Or KeyDown(KEY_A)
				Return True
			Endif
		#EndIf
		If type=keyboard
			If KeyDown(KEY_LEFT) Or KeyDown(KEY_A)
				Return True
			Else
				Return False
			End
		Elseif type=virtual
			If vc.MoveLeft()
				Return True
			Else
				Return False
			End
#If TARGET<>"flash"
		Elseif type=touch
			If AccelW()<y-sensitivity
				Return True
			Else
				Return False
			End
#End
		End
		Return False
	End
	Method GoDown:Bool()
		#If TARGET="XNA"
			If JoyDown(JOY_DOWN) Or KeyDown(KEY_DOWN) Or KeyDown(KEY_S)
				Return True
			Endif
		#EndIf
		If type=keyboard
			If KeyDown(KEY_DOWN) Or KeyDown(KEY_S)
				Return True
			Else
				Return False
			End
		Elseif type=virtual
			If vc.MoveDown()
				Return True
			Else
				Return False
			End
#If TARGET<>"flash"
		Elseif type=touch
			If AccelH()<x-sensitivity
				Return True
			Else
				Return False
			End
#End
		End
		Return False
	End
	Method GoUp:Bool()
		#If TARGET="XNA"
			If JoyDown(JOY_UP) Or KeyDown(KEY_UP) Or KeyDown(KEY_W)
				Return True
			Endif
		#EndIf
		If type=keyboard
			If KeyDown(KEY_UP) Or KeyDown(KEY_W)
				Return True
			Else
				Return False
			End
		Elseif type=virtual
			If vc.MoveUp()
				Return True
			Else
				Return False
			End
#If TARGET<>"flash"
		Elseif type=touch
			If AccelH()>x+sensitivity
				Return True
			Else
				Return False
			End
#End
		End
		Return False
	End
	Method Shoot:Bool()
		#If TARGET="XNA"
			If JoyHit(JOY_A)
				Return True
			Endif
		#EndIf
		If type=keyboard
			If KeyHit(KEY_SPACE)
				Return True
			Else
				Return False
			End
		Elseif type=virtual
			If vc.Shoot()
				Return True
			Else
				Return False
			End
		Elseif type=touch
			If TouchHit(0)
				Return True
			Else
				Return False
			End
		End
		Return False
	End
	Method Erase:Bool()
		#If TARGET="XNA"
			If JoyHit(JOY_X)
				Return True
			Endif
		#EndIf
		If type=keyboard
			If KeyHit(KEY_ENTER)
				Return True
			Else
				Return False
			End
		Elseif type=virtual
			If vc.Erase()
				Return True
			Else
				Return False
			End
		Elseif type=touch
			If vc.eraserBig.Click()
				Return True
			Else
				Return False
			End
		End
		Return False
	End
End

Class Lvl Extends Button
	Field nextLevel:Button
	Field levelMenu:Button
	Field showSummary:Bool
	Field visiblePlane:Bool
	Field visibility:Int	'0= default, 1=fog, 2=dark, 3=thunderstorm
	Field locked:Bool
	Field inkF:Bool
	Field level:Int
	Field score:Int
	Field grade:Float
	Field objects:Int
	Field monsters:Int
	Field enemyType:Int
	Field speed:Float
	Field lock:GameImage
	Field icon:GameImage
	Field enemyImg:GameImage
	
	Method New(level:Lvl)
		showSummary=False
		Self.level=level.level
		Self.visiblePlane=level.visiblePlane
		Self.visibility=level.visibility
		Self.score=0
		Self.grade=0
		Self.inkF=level.inkF
		Self.objects=level.objects
		Self.monsters=level.monsters
		Self.speed=level.speed
		Self.enemyType=level.enemyType
		Self.enemyImg=level.enemyImg
		nextLevel=New Button(game.images.Find("next"),dW*.65,dH*.3)
		levelMenu=New Button(game.images.Find("levelMenu"),dW*.65,dH*.5)
	End
	
	Method New(level:Int,x:Int,y:Int)
		showSummary=False
		visiblePlane=True
		visibility=0
		img=game.images.Find("note")
		lock=game.images.Find("lock")
		Self.level=level
		Self.score=0
		Self.grade=0
		Self.x=x
		Self.y=y
		Self.w=img.w
		Self.h=img.h
		midHandle=True
		If level=1
			locked=False
		Else
			locked=False
		End
		If level>0 And level<6
			inkF=False
		Else
			inkF=True
		End
		enemyType=e1
		enemyImg=game.images.Find("monster")
		nextLevel=New Button(game.images.Find("next"),dW*.65,dH*.3)
		levelMenu=New Button(game.images.Find("levelMenu"),dW*.65,dH*.5)
	End
	
	Method DrawSummary:Void()
		If currentLvl.level<60
			nextLevel.Draw()	
		Endif
		levelMenu.Draw()
		game.images.Find("clipboard").Draw(dW*.5,dH*.45)
		blackFont.DrawText("Monsters:"+monsters,dW*.4,dH*.35)
		blackFont.DrawText("Objects:"+objects,dW*.4,dH*.45)
		DrawText(score,dW*.4,dH*.65)
		If grade-Int(grade) >0
			game.images.Find("grade").Draw(dW*.59,dH*.65,0,1,1,grade-.1)
			game.images.Find("grade").Draw(dW*.62,dH*.65,0,1,1,0)
		Else
			game.images.Find("grade").Draw(dW*.6,dH*.65,0,1,1,grade)
		End
		Scale(.5,.5)
		DrawText "LEVEL "+Self.level,dW,dH*.5,.5,0
		Scale(2,2)
	End
	
	Method Draw:Void()
		DrawImage(img.image,x,y,rotation,1,1)
		If locked
			DrawImage(lock.image,x+lock.w*.6,y+lock.h*.3,rotation,1,1)
		Else
			DrawText(Self.level,x,y+dH*.01,.5,.5)
			If Self.level>5
				icon.Draw(x-img.w/2,y+img.h/2)
			End
			blackFont.DrawText(score,x,y+img.h*.5)
			If grade>0
				If grade-Int(grade) >0
					game.images.Find("grade").Draw(x+img.w*.7,y,0,1,1,grade-.1)
					game.images.Find("grade").Draw(x+img.w*1,y,0,1,1,0)
				Else
					game.images.Find("grade").Draw(x+img.w*.7,y,0,1,1,grade)
				End
			End
		End
	End
End