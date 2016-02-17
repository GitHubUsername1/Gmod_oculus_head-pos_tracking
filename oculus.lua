if CLIENT then

	local _DEBUG = false
	
	local draw = draw 
	local math = math
	local type = type
	local net = net
	local Angle = Angle
	local pitch, roll, yaw, x, y, z = 0
	
	surface.CreateFont("terminaltitle", {font="Myriad Pro", size=18, antialias=true}) --Title
	
	oculusGameData = {}
		oculusGameData.pitch = 0
		oculusGameData.roll = 0
		oculusGameData.yaw = 0
		oculusGameData.x = 0
		oculusGameData.y = 0
		oculusGameData.z =0
			
	local function OVRupdate_timer() 	

		pitch, roll, yaw, x, y, z = OVRupdate()
		oculusGameData.pitch = pitch
		oculusGameData.roll = roll
		oculusGameData.yaw = yaw
		oculusGameData.x = x
		oculusGameData.y = y
		oculusGameData.z = z
		
		local ang1 = Angle(-1*oculusGameData.pitch, 0, 0)		//pitch
		local ang2 = Angle(0,oculusGameData.yaw,0)				//yaw
		local ang3 = Angle(0,0,oculusGameData.roll)				//roll
		ang3:RotateAroundAxis( ang3:Right(), -1*ang1[1] )
		ang3:RotateAroundAxis( ang3:Up(), ang2[2] )
		Var_Oculus_Angle_W =  ang3
			
	end
	
	local RecenterHMD = function(the_player, key_number)
		if (key_number == IN_SCORE) then
			print("\nin recenter lua")
			OVRrecenterPose()
		end
	end
	
	local function draw_debuginfos()
		draw.RoundedBox(1, 150, 150, 450, 450, Color(64, 134, 195,170))
		draw.SimpleText("Actual Pitch : " .. oculusGameData.pitch .. "°" , "terminaltitle", 170, 250, Color(255,255,255)) 
		draw.SimpleText("Actual Roll : " .. oculusGameData.roll  .. "°", "terminaltitle", 170, 300, Color(255,255,255))
		draw.SimpleText("Actual Yaw : " .. oculusGameData.yaw  .. "°", "terminaltitle", 170, 350, Color(255,255,255))
		draw.SimpleText("Actual Raw X : " .. oculusGameData.x .. " cm", "terminaltitle", 170, 400, Color(255,255,255))
		draw.SimpleText("Actual Raw Y : " .. oculusGameData.y  .. " cm", "terminaltitle", 170, 450, Color(255,255,255))	
		draw.SimpleText("Actual Raw Z : " .. oculusGameData.z  .. " cm", "terminaltitle", 170, 500, Color(255,255,255))	
	end
	
	local function RotateVector(vector, angle) 
		local _vector = vector
		local _angle = angle
		_vector:Rotate(angle)
		return _vector
	end

	local function RotateVectorAroundAxis( angle, axis, degree )
		local angle1 = angle
		angle1:RotateAroundAxis( axis, degree )
		return angle1
	end
	
	local function OculusView (ply, origin, angles, fov, znear, zfar )
			local view = {}
			
			view.origin 		=  ( angles:Forward()*10 ) + ply:GetAttachment(ply:LookupAttachment("eyes")).Pos + (RotateVector(Vector(-1*oculusGameData.z,(-1*oculusGameData.x),0), angles)) --3rd person view
			--view.origin 		=  origin + (RotateVector(Vector(-1*oculusGameData.z,(1*oculusGameData.x),0), angles)) --1st person view
			view.origin			= ( angles:Forward()*10 ) + ply:GetAttachment(ply:LookupAttachment("eyes")).Pos + (RotateVector(Vector(-1*oculusGameData.z,(1*oculusGameData.x),0), angles)) 
			view.angles			= angles + (Var_Oculus_Angle_W or Angle(0,0,0))
			view.fov 			= 115
			view.znear			= znear
			view.zfar			= zfar
			view.drawviewer		= true
			return view
	end
	
	print("requiring oculus")
	require("oculus") 

	hook.Add("KeyPress", "My button hook", RecenterHMD)		
		
	timer.Create("OVRupdate_timer_func", 1/75, 0, OVRupdate_timer) --executes OVRupdate on a timer 75 times per sec
		
	if  _DEBUG then 
		hook.Add("HUDPaint", "oculus debug", draw_debuginfos)
	end
		
	hook.Add("CalcView", "oculus view", OculusView) -- hook.Remove("CalcView", "oculus view")

	--local function MessageFunction()
		--Entity( 1 ):PrintMessage( HUD_PRINTTALK, "(-2*oculusGameData.x):  " ..(-2*oculusGameData.x) )
	--end
	--timer.Create("print pitch", 1, 0, MessageFunction)
end