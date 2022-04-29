package config;

import java.io.IOException;

import common.Base;
import common.Report;

public class Constants {	
	
	private static String userDir = System.getProperty("user.dir");
	public static final String config = userDir + "\\src\\main\\java\\config\\Config.properties"; 
	public static final String filter = userDir + "\\src\\main\\java\\config\\Filter.properties";
	public static final String runtime = userDir + "\\src\\main\\java\\config\\Runtime.properties";
	public static final String dataValidationConfig = userDir + "\\src\\main\\java\\config\\DataValidationConfig.properties";
	public static final String driver = userDir + "\\src\\test\\resources\\chromedriver.exe";
	public static final String reportPath = userDir + "\\reports\\";
	public static final String downloadPath = userDir + "\\CSVFiles\\";	
	public static final String sqlPath = userDir + "\\src\\main\\java\\sql\\";
	public static int moduleErrCounter=0;
	public static boolean errFlag;
	
	public static String repPath() throws IOException {
		return reportPath + Base.getStringRunTimeData("test")+ "_report_" + Report.getReportDateFormat() + ".xlsx";
	} 
	public static String testPlan() throws IOException {
		return userDir + "\\src\\main\\java\\testPlan\\" + Base.getStringConfigData("testPlan") + ".csv";
	} 
}
