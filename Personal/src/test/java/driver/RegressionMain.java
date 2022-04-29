package driver;

import java.awt.AWTException;
import java.io.IOException;
import java.sql.SQLException;
import java.text.ParseException;

import common.Base;
import common.Tests;

public class RegressionMain {
	
	public static void main(String[] args) throws IOException, InterruptedException, ParseException, SQLException, AWTException  {		
		Tests run  = new Tests();
		if (Base.getBooleanConfigData("executeRegression")) run.drillDownAndUIChecks();
		if (Base.getBooleanConfigData("executeFilters")) run.globalFilterChecks();	
	}	
}
