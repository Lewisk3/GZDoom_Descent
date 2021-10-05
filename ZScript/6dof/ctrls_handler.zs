class SDOF_MovementHandler : EventHandler
{
    const rollAmount = 4 * 65536.0 / 360;

    int roll;

    override void UiTick()
    {
        players[consolePlayer].cmd.roll = roll;
    }

    override void NetworkProcess(ConsoleEvent e)
    {
		let dscplr = DescentPlayer(players[e.Player].mo);
	
        if (e.name ~== "+rollleft" || e.name ~== "-rollright") roll -= rollAmount;
        else if (e.name ~== "+rollright" || e.name ~== "-rollleft") roll += rollAmount;
		
		if(dscplr)
		{
			if(e.name ~== "rearview") dscplr.rearview = !dscplr.rearview;
		}
    }
}