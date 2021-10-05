class SixDoFPlayer : PlayerPawn
{
	bool controlInvert;
    Property UpMove : upMove;

    Default
    {
        Speed 0.24;
        SixDoFPlayer.UpMove 0.12;

        +NoGravity
        +RollSprite
    }

    const maxYaw = 65536.0;
    const maxPitch = 65536.0;
    const maxRoll = 65536.0;
    const Friction = 0.90;
	vector3 viewAngles;
	vector3 accel;
	
    double upMove;
    Quaternion targetRotation;


    override void PostBeginPlay()
    {
        Super.PostBeginPlay();

        bFly = true;
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
        UserCmd cmd = player.cmd;

		viewAngles *= 0.90;
		vel *= Friction;
		accel *= Friction;
		ViewRoll *= 0.90;
		ViewRoll = clamp(ViewRoll, -30, 30);

		double zMove = 0;
	    if (IsPressed(BT_Jump  )) zMove =  upMove;
        if (IsPressed(BT_Crouch)) zMove =  -upMove;

        if (cmd.forwardMove || cmd.sideMove || zMove)
        {
			double fm, sm, um;
			
			// Prevent division by zero.
			if(cmd.forwardMove || cmd.sideMove)
			{
				vector2 dir_xy = (cmd.forwardMove, cmd.sideMove).Unit();
				fm = dir_xy.x   *  Speed;
				sm = dir_xy.y   *  Speed;
				
				/*
				if(sm)
				{
					double tiltView = DSCMath.Sign(sm) * 1.5;
					ViewRoll += tiltView;
				}
				*/
			}
			if(zMove) um = zMove;
			
            Vector3 forward, right, up;
            [forward, right, up] = Quaternion.GetActorAxes(self, (1, controlInvert ? -1 : 1,1));

            Vector3 wishVel = fm * forward + sm * right + um * up;
			accel += wishVel;
           
            if (!(player.cheats & CF_PREDICTING)) PlayRunning();

			if (player.cheats & CF_REVERTPLEASE)
			{
				player.cheats &= ~CF_REVERTPLEASE;
				player.camera = player.mo;
			}
        }
		
		vel += accel;
		player.vel = vel.xy;
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

	virtual void ThrustView(double tAngle, double tPitch, double tRoll)
	{
		vector3 viewScale = (
			360 / maxYaw, 
			360 / maxPitch, 
			360 / maxRoll
		);
		
		viewAngles.x += tAngle * (1/viewScale.x);
	}

    virtual void RotatePlayer()
    {
        // Find target rotation
        UserCmd cmd = player.cmd;
        double cmdYaw = cmd.yaw * 360 / maxYaw;
        double cmdPitch = -cmd.pitch * 360 / maxPitch;
        double cmdRoll = cmd.roll * 360 / maxRoll;
		cmdYaw += viewAngles.x;
		cmdPitch += viewAngles.y;
		cmdRoll += viewAngles.z;
		
		if(controlInvert) cmdPitch *= -1;
		
		if(cmdYaw)
		{
			ViewRoll -= (cmdYaw * 0.5);
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


    bool IsPressed(int bt)
    {
        return player.cmd.buttons & bt;
    }

    bool JustPressed(int bt)
    {
        return (player.cmd.buttons & bt) && !(player.oldButtons & bt);
    }
}