package common;

import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.sql.SQLException;
import java.text.DecimalFormat;
import java.text.NumberFormat;
import java.text.ParseException;
import java.util.ArrayList;

import org.openqa.selenium.WebDriver;
import com.opencsv.CSVReader;

import config.Constants;
import pages.VizPage;

public class DataValidation {

	public WebDriver driver;
	Common func;
	Sync wait;
	Report report;
	VizPage viz;
	Database db;

	public DataValidation(WebDriver driver) throws IOException {
		this.driver = driver;	
		this.func = new Common(driver);
		this.wait = new Sync(driver);
		this.viz = new VizPage(driver);
    	this.report = new Report();
    	this.db = new Database();
	}
	
	
	/**
	 * 
	 * @param filePath
	 * @return
	 * @throws IOException 
	 */
	public ArrayList<String> readCSV(String filePath) throws IOException {
	    try {
			ArrayList<String> data = new ArrayList<String>();		    
		    CSVReader reader = new CSVReader(new FileReader(filePath));      
		    String [] nextLine;      
		    while ((nextLine = reader.readNext()) != null) {
		    	String temp = "";
		    	for (int i = 0; i < nextLine.length; i++) {
		    		if (i < nextLine.length - 1) {
		    			while(nextLine[i].indexOf("|") >= 0) {
		    				nextLine[i] = nextLine[i].replace("|", ""); 
	    				}
		    			temp += nextLine[i] + "|";
		    		} else {
		    			while(nextLine[i].indexOf("|") >= 0) {
		    				nextLine[i] = nextLine[i].replace("|", ""); 
	    				}
		    			temp += nextLine[i];
		    		}		    		
		    	}  
		    	data.add(temp);
		    }		    
	        return data;
	    } catch (Exception e) {
	    	report.error("Action", "[Export CSV] CSV file read exception (" + e.getMessage() + ")");
	    }
		return null;
	}
	
	
	/**
	 * 
	 * @param vizName
	 * @return
	 * @throws IOException
	 * @throws InterruptedException
	 * @throws ParseException 
	 */
	public ArrayList<String> exportCSV(String vizName) throws IOException, InterruptedException, ParseException {
		func.getCSV(1, "pItemsPerPage", Base.getNumericConfigData("noOfCsvRecords"));
		func.getElement(viz.btnExportCSV()).click();
		report.success("Action", "[Export CSV] Export CSV triggered");
		String downloadPath = Constants.downloadPath + vizName + " Crosstab.csv";
		ArrayList<String> csvDataList =  new ArrayList<String>();
		if (verifyFileExists(downloadPath, 30)) {
			csvDataList = readCSV(downloadPath);
			report.success("Action", "[Export CSV] CSV file downloaded with (" + (csvDataList.size()-1) + ") records");
			return csvDataList;
		} 
		else {
			if (verifyDownloadFileName(vizName)!= null) {
				vizName = verifyDownloadFileName(vizName);	
				downloadPath = Constants.downloadPath + vizName + " Crosstab.csv";
				csvDataList = readCSV(downloadPath);
				report.success("Action", "[Export CSV] CSV file downloaded with (" + (csvDataList.size()-1) + ") records");
				return csvDataList;
			}
		}
		return null;
	}
	
	
	/**
	 * 
	 * @param vizName
	 * @return
	 * @throws IOException
	 * @throws InterruptedException
	 * @throws ParseException 
	 */
	public ArrayList<String> exportAllCSV(String vizName) throws IOException, InterruptedException, ParseException {
		if (func.getElement(viz.btnExportAllExport()).isDisplayed()) {
			func.getElement(viz.btnExportAllExport()).click();
			String downloadPath = Constants.downloadPath + vizName + " Crosstab.csv";
			ArrayList<String> csvDataList =  new ArrayList<String>();
			if (verifyFileExists(downloadPath, 180)) {
				csvDataList = readCSV(downloadPath);
				report.success("Action", "[Export All CSV] CSV file downloaded with (" + (csvDataList.size()-1) + ") records");
				return csvDataList;
			} 
			else {
				if (verifyDownloadFileName(vizName)!= null) {
					vizName = verifyDownloadFileName(vizName);	
					downloadPath = Constants.downloadPath + vizName + " Crosstab.csv";
					csvDataList = readCSV(downloadPath);
					report.success("Action", "[Export All CSV] CSV file downloaded with (" + (csvDataList.size()-1) + ") records");
					return csvDataList;
				}
			}
		}
    	report.error("Action", "[Export All CSV] (" + vizName + ") CSV file failed to download");
		return null;
	}
	

	/**
	 * 
	 * @param downloadPath
	 * @param duration
	 * @return
	 * @throws IOException
	 * @throws InterruptedException
	 */
	public boolean verifyFileExists(String downloadPath, int duration) throws IOException, InterruptedException {
		File f = new File(downloadPath);
		for(int i = 0; i <= duration; i++) {
			if(f.exists()) 
				return true;
			else 
				Thread.sleep(1000);					 
		}
		return false;
	}

	
	/**
	 * 
	 * @param vizName
	 * @return
	 * @throws InterruptedException
	 */
	public boolean csvFileDelete(String vizName) throws InterruptedException {
		File f = new File(Constants.downloadPath + vizName + " Crosstab.csv");
		for(int i = 0; i <= 30; i++) {
			if(f.exists())
				f.delete();
			else
				return true;			
			Thread.sleep(500);
		}
		return false;
	}	

	
	/**
	 * 
	 * @param number
	 * @return
	 */
	public String convertFromEpsilionNotation(double number) {
	    if (String.valueOf(number).toLowerCase().contains("e")) {
	        NumberFormat formatter = new DecimalFormat();
	        formatter.setMaximumFractionDigits(25);
	        return formatter.format(number).replaceAll(",", "");
	    } else {
	        return String.valueOf(number);	    	
	    }
	}
	
	
	/**
	 * 
	 * @param matchedLogs
	 * @param unMatchedLogs
	 * @param dbDataType
	 * @param source
	 * @param ruleException
	 * @throws IOException
	 * @throws InterruptedException
	 */
	public void dataValidationLogs(ArrayList<String> matchedLogs, ArrayList<String> unMatchedLogs, ArrayList<String> dbDataType, ArrayList<String> source, boolean ruleException) throws IOException, InterruptedException{
		
		if (matchedLogs.size() == (source.size()-1)) {
	    	if (Base.getBooleanConfigData("needSuccessValidationLog")) {
	    		for (int i=0; i<matchedLogs.size();i++ ) {
	    			String[] temp = matchedLogs.get(i).split("\\|");
	    			if (temp.length == dbDataType.size()) {
	    				String str = "";
	    				for (int j=0; j<dbDataType.size(); j++) {
    						String sourceColumnHeader = dbDataType.get(j).split(":")[0];
							str += "[" +  sourceColumnHeader + ": " + temp[j] + "] ";
	    				}
				    	report.success("Matched", str);
	    			}
	    		}
	    	}
	    	report.success("Message", "[Data Validation] Data validation passed successfully");
    	}
    	else if (ruleException) {
	    	if (Base.getBooleanConfigData("needSuccessValidationLog")) {
	    		for (int i=0; i<matchedLogs.size();i++ ) {
	    			String[] temp = matchedLogs.get(i).split("\\|");
	    			if (temp.length == dbDataType.size()) {
	    				String str = "";
	    				for (int j=0; j<dbDataType.size(); j++) {
    						String sourceColumnHeader = dbDataType.get(j).split(":")[0];
							str += "[" +  sourceColumnHeader + ": " + temp[j] + "] ";
	    				}
				    	report.success("Matched", str);
	    			}
	    		}
	    	}
	    	report.success("Message", "[Data Validation] Data validation passed successfully");
    	} 
    	else {
	    	if (unMatchedLogs.size() > 0) {	    		
	    		ArrayList<String> tempLogs =  new ArrayList<String>();
	    		for (int i=0; i<unMatchedLogs.size();i++ ) {
	    			if (unMatchedLogs.get(i).split("\\|").length == dbDataType.size()) {
	    				tempLogs.add(unMatchedLogs.get(i));
	    			}
	    		}
	    		
		    	if (tempLogs.size() > 0) {
			    	report.success("Message", "[Data Validation] Data validation completed with error(s): The following (" + tempLogs.size() + ") CSV record(s), does not exists in database..");
			    	
		    		for (int i=0; i<tempLogs.size();i++ ) {
		    			String[] temp = tempLogs.get(i).split("\\|");
		    			if (temp.length == dbDataType.size()) {
		    				String str = "";
		    				for (int j=0; j<dbDataType.size(); j++) {
	    						String sourceColumnHeader = dbDataType.get(j).split(":")[0];
								str += "[" +  sourceColumnHeader + ": " + temp[j] + "] ";
		    				}
					    	report.error("Not Matched", str);
		    			}
		    		}
		    	}
		    	else {
			    	report.success("Message", "[Data Validation] Data validation passed successfully");
		    	}
	    	}
    	}	
    	report.success("Message", "[Data Validation] Number of CSV records validated with database: " + (source.size()-1));
    	report.success("Message", "[Data Validation] Data validation completed..");
	}
	

	/**
	 * 
	 * @param vizName
	 * @param sqlLabel
	 * @throws IOException
	 * @throws SQLException
	 * @throws InterruptedException
	 * @throws ParseException 
	 */
	public boolean dataValidation(String vizName, String sqlLabel) throws IOException, SQLException, InterruptedException, ParseException {
		Constants.moduleErrCounter = 0;
		report.cleanDirectory(Constants.downloadPath);		
		if (rulesEngine(vizName, exportCSV(vizName), db.getColumnDataTypeFromClientDb(db.getSQL(sqlLabel)), db.getDataFromClientDb(db.getSQL(sqlLabel)))) {			
			if (Base.getBooleanConfigData("executeRegression")) report.updateModuleReportDataValidationSteps();
			return true;
		} else {
			if (Base.getBooleanConfigData("executeRegression")) report.updateModuleReportDataValidationSteps();
			return false;
		}
	}

	
	/**
	 * 
	 * @param vizName
	 * @param params
	 * @throws IOException
	 * @throws SQLException
	 * @throws InterruptedException
	 * @throws ParseException 
	 */
	public boolean dataValidation(String vizName, ArrayList<String> params) throws IOException, SQLException, InterruptedException, ParseException {
		Constants.moduleErrCounter = 0;
		report.cleanDirectory(Constants.downloadPath);	
		
		if (rulesEngine(vizName, exportCSV(vizName), db.getColumnDataTypeFromClientDb(params), db.getDataFromClientDb(params))) {
			if (Base.getBooleanConfigData("executeRegression")) report.updateModuleReportDataValidationSteps(); return true;
		} else {
			if (Base.getBooleanConfigData("executeRegression")) report.updateModuleReportDataValidationSteps(); return false;
		}
	}
	
	
	/**
	 * 
	 * @param vizName
	 * @param csvDataList
	 * @param dbDataType
	 * @param dbDataList
	 * @return 
	 * @throws IOException
	 * @throws SQLException
	 * @throws InterruptedException
	 */
	public boolean rulesEngine(String vizName, ArrayList<String> csvDataList, ArrayList<String> dbDataType, ArrayList<String> dbDataList) {
		
		ArrayList<String> source =  new ArrayList<String>();
		ArrayList<String> target =  new ArrayList<String>();
		ArrayList<String> matchedLogs =  new ArrayList<String>();
		ArrayList<String> unMatchedLogs =  new ArrayList<String>();
		
		try {
			if (csvDataList != null) {	
				report.success("Message", "[Data Validation] Data validation started...");
				source = csvDataList;
				target = dbDataList;
					
				String[] sourceHeader = source.get(0).split("\\|");
				String[] targetHeader = target.get(0).split("\\|");
				boolean ruleExemption = false;
				if (sourceHeader.length == targetHeader.length) {
						
					for (int i=1; i<source.size(); i++) {											
						boolean matchFoundinTarget = false;
						boolean commaFoundinSource = false;
						boolean zeroInSource = false;
			    		String[] sourceData = source.get(i).split("\\|");
			    		for (int j=1; j<target.size(); j++) { 
				    		String[] targetData = target.get(j).split("\\|");	
				    		int counter = 0;								    		
			    			for (int k=0; k<sourceData.length; k++) {
								String sourceColumnHeader = dbDataType.get(k).split(":")[0];
								String sourceDataType = dbDataType.get(k).split(":")[1];
			    				for(int m=0; m<targetData.length; m++) {
									String targetColumnHeader = dbDataType.get(m).split(":")[0];
									String targetDataType = dbDataType.get(m).split(":")[1];
									String tempSource = sourceData[k];							
									String tempTarget = targetData[m];
									
									if ((sourceDataType.equals("numeric") && targetDataType.equals("numeric")) ||
										(sourceDataType.equals("int") && targetDataType.equals("int")) ||
										(sourceDataType.equals("decimal") && targetDataType.equals("decimal")) ||
										(sourceDataType.equals("float") && targetDataType.equals("float"))) {	
										
										if (tempSource.indexOf(',') != -1) {
											commaFoundinSource = true;
											break;
										}
										
										if (!tempSource.equalsIgnoreCase("null")) {
											if (!tempTarget.equalsIgnoreCase("null")) {
												tempSource = convertFromEpsilionNotation(Double.parseDouble(sourceData[k]));							
												tempTarget = convertFromEpsilionNotation(Double.parseDouble(targetData[m]));						
											
												if (sourceHeader[k].equals("Fees") || sourceHeader[k].equals("Spend")) {
													if (tempSource.equals("0") || tempSource.equals("0.0")) {
														zeroInSource = true;
														break;
													}
												}
												
												if (((sourceColumnHeader.indexOf("%")!= -1) && (targetColumnHeader.indexOf("%")!= -1)) ||
													((sourceColumnHeader.indexOf("Percent")!= -1) && (targetColumnHeader.indexOf("Percent")!= -1))) {
													tempSource = String.valueOf(Double.parseDouble(tempSource) * 100);
												} 
												
						    					if ((String.valueOf(Math.round(Double.parseDouble(tempSource))).equals(tempTarget))
						    						|| (tempSource.equals(String.valueOf(Math.round(Double.parseDouble(tempTarget)))))
						    						|| (String.valueOf(Math.round(Double.parseDouble(tempSource))).equals(String.valueOf(Math.round(Double.parseDouble(tempTarget)))))
						    						|| ((String.valueOf(Math.round(Double.parseDouble(tempSource)) + 1)).equals(String.valueOf(Math.round(Double.parseDouble(tempTarget)))))
						    						|| ((String.valueOf(Math.round(Double.parseDouble(tempSource)))).equals((String.valueOf(Math.round(Double.parseDouble(tempTarget)) + 1))))
						    						){
						    						counter++;
						    						if (counter == sourceData.length) {
						    							matchFoundinTarget = true;								    							
						    						}	
						    						break;
						    					}					    					
											}
										}
									}
									
									else {
										if (tempSource.equals("Null")) 
											tempSource = "null";
			
				    					if (tempSource.trim().equals(tempTarget.trim())) {
				    						counter++;
				    						if (counter == sourceData.length) {
				    							matchFoundinTarget = true;								    							
				    						}
				    						break;
				    					}	
									}								
			    				}
			    			}							    			
							if (matchFoundinTarget) {
								matchedLogs.add(source.get(i));
								break;
							}
							if (commaFoundinSource) {
								break;
							}
							if (zeroInSource) {
								ruleExemption = true;
								break;
							}
			    		}
			    		if (!matchFoundinTarget) {
							unMatchedLogs.add(source.get(i));
			    		}								    		
					}		
					dataValidationLogs(matchedLogs, unMatchedLogs, dbDataType, source, ruleExemption);	
					return true;
				}	
				else {
			    	report.error("Not Matched", "[Data Validation] SQL and CSV column counts are not matching. Hence not able to proceed data validation..");
			    	return false;
				}
			}
			else {
		    	report.error("Message", vizName + " Crosstab.csv file not exists in the download path");
		    	return false;
			}		
		} catch (NumberFormatException e) {
		 	try {
				report.error("Message", "[Data Validation] Exported CSV file is broken. Hence not able to proceed data validation. Exception Captured: " + e.fillInStackTrace());
				return false;
			} catch (IOException e1) {return false;}	
		} catch (NullPointerException e) {
			try {
				report.error("Message", "[Data Validation] SQL needs an update. Hence not able to proceed data validation. Exception Captured: " + e.fillInStackTrace());
			} catch (IOException e1) {return false;}
		} catch (Exception e) {
				e.printStackTrace();
		}
		return false;	
	}
	
	
	
	/**
	 * 
	 * @param vizName
	 * @return
	 */
	private String verifyDownloadFileName(String vizName) {
		switch(vizName) {
			case "Legal Spend Breakdown by GB Business Unit":  
				return "Legal Spend Breakdown by Business Unit";
			case "Legal Spend Breakdown by Client Level":  
				return "Legal Spend by Practice Area";
			case "Vendor Budget vs. Actual by GB Business Unit":  
				return "Vendor Budget vs. Actual by Business Unit";
			case "Top Vendors by Fees by Role":  
				return "Top Vendors by Spend by Role";
		}
		return null;
	}	
}
