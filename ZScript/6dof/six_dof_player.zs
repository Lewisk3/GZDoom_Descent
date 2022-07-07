class SixDoFPlayer : PlayerPawn
{
	bool controlInvert;
    Property UpMove : upMove;

    const maxYaw = 65536.0;
    const maxPitch = 65536.0;
    const maxRoll = 65536.0;
    const Friction = DSCMOVEFRICT;
	double lookMod;
	double viewFriction;
	vector3 forceInput;
	vector3 viewAngles;
	vector3 adjustView;
	vector3 accel;
	vector3 prevPos; // Try and detect teleport.

    double upMove;
    Quaternion targetRotation;
	
	Property ViewFriction : viewFriction;
	Property LookSpeed : lookMod;
	
	Default
	{
		Gravity 0;
		Speed DSCMOVESPEED; // 0.18
		SixDoFPlayer.ViewFriction 0.90;
		SixDoFPlayer.LookSpeed 1.0;
        SixDoFPlayer.UpMove 0.10;
        +RollSprite;
		+SlidesOnWalls;
	}

	clearscope bool checkVoodoo() 
	{ 
		return (!player || !player.mo || player.mo != self);
	}

    override void PostBeginPlay()
    {
        Super.PostBeginPlay();

        bFly = true;
        targetRotation.FromEulerAngle(angle, pitch, roll);
    }
	
	virtual void ResetRotation()
	{
		viewAngles *= 0;
		pitch = 0;
		roll = 0;
		targetRotation.FromEulerAngle(angle, pitch, roll);
	}

    override void HandleMovement()
    {				
        if (reactionTime) --reactionTime;   // Player is frozen
        else
        {
            CheckQuickTurn();
            RotatePlayer();
            MovePlayer();
        }
    }

    override void CheckCrouch(bool totallyFrozen) {}
    override void CheckPitch() {}

    override void MovePlayer()
    {	
		vector3 moveDelta = level.vec3diff(prevPos, pos);
		if( !(moveDelta ~== (0,0,0)) && moveDelta.Length() > vel.Length()*2.0)
		{
			// Reset interpolation, maybe we teleported?
			targetRotation.FromEulerAngle(angle, pitch, roll);
		}
		
        UserCmd cmd = player.cmd;

		viewAngles *= viewFriction;			
		vel *= Friction;
		accel *= Friction;
		ViewRoll *= 0.90;
		ViewRoll = clamp(ViewRoll, -30, 30);
		
		// player.onground = (pos.z <= floorz) || bOnMobj || bMBFBouncer || (player.cheats & CF_NOCLIP2);

		double zMove = 0;
	    if (IsPressed(BT_Jump  )) zMove =  upMove;
        if (IsPressed(BT_Crouch)) zMove =  -upMove;

		vector3 moveInputs = (cmd.forwardMove, cmd.sideMove, zMove);
		if(forceInput.x) moveInputs.x = forceInput.x; 
		if(forceInput.y) moveInputs.y = forceInput.y;
		if(forceInput.z) moveInputs.z = forceInput.z;

        if (moveInputs.Length())
        {
			DoAccelerate(moveInputs.x, moveInputs.y, moveInputs.z);
           
            if (!(player.cheats & CF_PREDICTING)) PlayRunning();

			if (player.cheats & CF_REVERTPLEASE)
			{
				player.cheats &= ~CF_REVERTPLEASE;
				player.camera = player.mo;
			}
        }
		
		vel += accel;
		player.vel = vel.xy;
		prevPos = pos;
    }
	
	virtual void DoAccelerate(double inputForward, double inputSide, double inputUp, double fw_mod = 1.0, double lr_mod = 1.0)
	{
		double fm, sm, um;
		um = inputUp;
		
		// Prevent division by zero.
		if(inputForward || inputSide)
		{
			vector2 dir_xy = (inputForward, inputSide).Unit();
			
			fm = dir_xy.x   *  (Speed * fw_mod);
			sm = dir_xy.y   *  (Speed * lr_mod);
		}

		Vector3 forward, right, up;
		[forward, right, up] = Quaternion.GetActorAxes(self, (1, controlInvert ? -1 : 1,1));

		Vector3 wishVel = fm * forward + sm * right + um * up;
		accel += wishVel;
	}
	
    virtual void CheckQuickTurn()
    {
        UserCmd cmd = player.cmd;

		if (JustPressed(BT_Turn180)) player.turnticks = turn180_ticks;

        if (player.turnTicks)
        {
            --player.turnTicks;
            cmd.yaw = floor(0.5 * maxYaw / turn180_ticks);
        }
    }

    virtual void RotatePlayer()
    {
        // Find target rotation
        UserCmd cmd = player.cmd;
        double cmdYaw = cmd.yaw * 360 / maxYaw;
        double cmdPitch = -cmd.pitch * 360 / maxPitch;
        double cmdRoll = cmd.roll * 360 / maxRoll;
		cmdYaw   += viewAngles.x;
		cmdPitch += viewAngles.y;
		cmdRoll  += viewAngles.z;
		
		cmdYaw *= lookMod;
		cmdPitch *= lookMod;
		cmdRoll *= lookMod;
		
		if(controlInvert) cmdPitch *= -1;
		
		if(cmdYaw)
		{
			ViewRoll -= (cmdYaw * 0.15);
		}

        Quaternion input;
        input.FromEulerAngle(cmdYaw, cmdPitch, cmdRoll);
        Quaternion.Multiply(targetRotation, targetRotation, input);

        // Interpolate to it
        Quaternion r;
        r.FromEulerAngle(angle, pitch, roll);

        Quaternion.Slerp(r, r, targetRotation, 0.2);

        double newAngle, newPitch, newRoll;
        [newAngle, newPitch, newRoll] = r.ToEulerAngle();

        A_SetAngle(newAngle, SPF_Interpolate);
        A_SetPitch(newPitch, SPF_Interpolate);
        A_SetRoll(newRoll, SPF_Interpolate);
    }


	override void CalcHeight()
	{
		double bob_angle = Level.maptime / (120 * TICRATE / 35.) * 360.;
		double bob = (0.06 * sin(bob_angle));
		
		vector3 worldOffs = DSCMath.V3Offset(angle, pitch, roll, 0,0,bob, 0.25);
		vel += worldOffs;
		
		player.viewz = (pos.Z + vel.z) + ViewHeight;
	}

    bool IsPressed(int bt)
    {
        return player.cmd.buttons & bt;
    }

    bool JustPressed(int bt)
    {
        return (player.cmd.buttons & bt) && !(player.oldButtons & bt);
    }
}