
#define GMMODULE

#include"Interface.h"
#include"ovr6dof.h"
#include<iostream>
#include<OVR.h>

using namespace OVR;
using namespace std;

bool initialise = false;
constexpr float d2r = 57.295781;

ovrHmd HMD;
double HmdFrameTiming;
ovrResult result;
ovrGraphicsLuid luid;
ovrTrackingState ts;
Posef pose;

ovr6dof output;					//rift raw tracking data
ovr6dof outputInitialise;		//used to recenter rift
ovr6dof outputGameData;			//head tracking + positional data in degree's/cm's in game

int DisplayLine(LPCTSTR pszTextLine)
{
	typedef void(*func)(const char* msg, ...);
	static func f = (func)GetProcAddress(GetModuleHandle("tier0.dll"), "Warning");
	f(pszTextLine);
	return 0;
} // CNPTestDlg::DisplayLine()

int OVRupdate(lua_State* state)
{
	HmdFrameTiming = ovr_GetPredictedDisplayTime(HMD, 0);
	ts = ovr_GetTrackingState(HMD, ovr_GetTimeInSeconds(), HmdFrameTiming);

	pose = ts.HeadPose.ThePose;
	pose.Rotation.GetEulerAngles<Axis_Y, Axis_X, Axis_Z>(&output.yaw, &output.pitch, &output.roll);

	output.x = pose.Translation.x;
	output.y = pose.Translation.y;
	output.z = pose.Translation.z;

	output.pitch = (output.pitch) * d2r;	//convert to degree's/cm's
	output.roll = (output.roll) * d2r;
	output.yaw = (output.yaw) * -d2r;
	output.x = (output.x) * -1e2;
	output.y = (output.y) * 1e2;
	output.z = (output.z) * 1e2;

	if (!initialise)
	{
		outputInitialise.pitch = output.pitch;
		outputInitialise.roll = output.roll;
		outputInitialise.yaw = output.yaw;
		outputInitialise.x = output.x;
		outputInitialise.y = output.y;
		outputInitialise.z = output.z;
		initialise = true;
	}

	outputGameData.pitch = output.pitch - outputInitialise.pitch;
	outputGameData.roll = output.roll - outputInitialise.roll;
	outputGameData.yaw = output.yaw - outputInitialise.yaw;
	outputGameData.x = output.x - outputInitialise.x;
	outputGameData.y = output.x - outputInitialise.x;
	outputGameData.z = output.z - outputInitialise.z;

	LUA->PushNumber(outputGameData.pitch);
	LUA->PushNumber(-1 * (outputGameData.roll));
	LUA->PushNumber(-1 * (outputGameData.yaw));
	LUA->PushNumber(outputGameData.x);
	LUA->PushNumber(outputGameData.y);
	LUA->PushNumber(outputGameData.z);
	return 6;
}

int OVRrecenterPose(lua_State* state)
{
	//ovr_RecenterPose(HMD);
	initialise = false;
	return 0;
}

GMOD_MODULE_OPEN()
{
	LUA->PushSpecial(GarrysMod::Lua::SPECIAL_GLOB); // Push the global table
	LUA->PushCFunction(OVRupdate); // Push our function
	LUA->SetField(-2, "OVRupdate"); // 
	LUA->Pop(); // Pop the global table off the stack

	LUA->PushSpecial(GarrysMod::Lua::SPECIAL_GLOB);
	LUA->PushCFunction(OVRrecenterPose);
	LUA->SetField(-2, "OVRrecenterPose");
	LUA->Pop();

	result = ovr_Initialize(nullptr);
	if (!OVR_SUCCESS(result))
	{
		DisplayLine("error in initialise");
		return 1;
	}
	else
		DisplayLine("initialise ok ");

	result = ovr_Create(&HMD, &luid);
	if (!OVR_SUCCESS(result))
	{
		DisplayLine("error in create HMD");
		return 1;
	}
	else
		DisplayLine("create HMD ok ");

	if (!HMD)
	{
		DisplayLine("error in !HMD");
		return 1;
	}
	else
		DisplayLine("!HMD ok ");

	ovr_ConfigureTracking(HMD, ovrTrackingCap_Orientation |
		ovrTrackingCap_MagYawCorrection |
		ovrTrackingCap_Position, 0);

	return 0;
}

// Called when the module closes
GMOD_MODULE_CLOSE()
{
	ovr_Destroy(HMD);
	ovr_Shutdown();

	return 0;
}
