class SDOF_MovementHandler : EventHandler
{
    const rollAmount = 4 * (65536.0 / 360);
	
    override void UiTick()
    {
        for(int i = 0; i < MAXPLAYERS; i++)
		{
			PlayerInfo plr = players[i];
			if(!plr) continue;
			
			
			let dscplr = DescentPlayer(plr.mo);
			if(!dscplr) continue;
			
			plr.cmd.yaw   += dscplr.adjustView.x;
			plr.cmd.pitch += dscplr.adjustView.y;
			plr.cmd.roll  += dscplr.adjustView.z;
		}
    }
	
    override void NetworkProcess(ConsoleEvent e)
    {
		let dscplr = DescentPlayer(players[e.Player].mo);
		if(!dscplr) return;
		
		bool rollRight = e.name ~== "+rollleft"  || e.name ~== "-rollright";
		bool rollLeft  = e.name ~== "+rollright" || e.name ~== "-rollleft";
        if (rollRight) dscplr.adjustView.z -= rollAmount;
		if (rollLeft ) dscplr.adjustView.z += rollAmount;
    }
}