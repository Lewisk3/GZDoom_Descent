class SDOF_MovementHandler : EventHandler
{
    override void UiTick()
    {
        for(int i = 0; i < MAXPLAYERS; i++)
		{
			if(!PlayerInGame[i]) continue;
			PlayerInfo plr = players[i];
			if(!plr) continue;
			
			
			let dscplr = DescentPlayer(plr.mo);
			if(!dscplr) continue;
			
			plr.cmd.yaw   += dscplr.adjustView.x;
			plr.cmd.pitch += dscplr.adjustView.y;
			plr.cmd.roll  += dscplr.adjustView.z;
		}
    }
	
	override void WorldLoaded(WorldEvent e)
	{
		for(int i = 0; i < MAXPLAYERS; i++)
		{
			if(!PlayerInGame[i]) continue;
			PlayerInfo plr = players[i];
			if(!plr) continue;
			
			let dscplr = DescentPlayer(plr.mo);
			if(!dscplr) continue;
			
			dscplr.HandleLevelLoaded();
		}	
	}
	
    override void NetworkProcess(ConsoleEvent e)
    {
		let dscplr = DescentPlayer(players[e.Player].mo);
		if(!dscplr) return;
		
		if(e.name ~== "+rollleft")
			dscplr.rollingLeft = true;
		else if(e.name ~== "-rollleft")
			dscplr.rollingLeft = false;
			
		if(e.name ~== "+rollright")
			dscplr.rollingRight = true;
		else if(e.name ~== "-rollright")
			dscplr.rollingRight = false;
    }
}