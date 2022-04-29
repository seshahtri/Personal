package driver;

import java.awt.AWTException;
import java.io.IOException;
import java.sql.SQLException;
import java.text.ParseException;

import org.testng.annotations.Test;

import common.Base;
import common.Tests;

public class Regression {
	
	@Test
	public void RegressionDriver() throws IOException, SQLException, InterruptedException, ParseException, AWTException {
		Tests run  = new Tests();
		if (Base.getBooleanConfigData("executeRegression")) run.drillDownAndUIChecks();
		if (Base.getBooleanConfigData("executeFilters")) run.globalFilterChecks();	
	}	
}
