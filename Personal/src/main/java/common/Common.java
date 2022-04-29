package common;

import java.io.IOException;
import java.text.ParseException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.openqa.selenium.By;
import org.openqa.selenium.JavascriptExecutor;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;

import config.Constants;


public class Common {
	
	public WebDriver driver;	
	Sync wait;
	Report report;
	public Common(WebDriver driver) throws IOException {
		this.driver = driver;	
		this.wait = new Sync(driver);
		this.report = new Report();
	}	
	
	/**
	 * 
	 * @param obj
	 * @return
	 * @throws IOException
	 * @throws InterruptedException
	 */
	public WebElement getElement(By obj) throws IOException  {
		try {			
			if (wait.waitUntilObjectLoad(obj))
				return driver.findElement(obj);			
		} catch (IOException e) {
			report.error("Message", e.getMessage());
		} catch (InterruptedException e) {
			report.error("Message", e.getMessage());
		} 
		return null;		
	}

	
	/**
	 * 
	 * @param vizName
	 * @return
	 * @throws IOException 
	 */
	public int getWorkBookName(String vizName) throws IOException {
		JavascriptExecutor executor = (JavascriptExecutor) driver;
		int index = 0;
		String vizLen = "function test() {" +
						"var vizes = tableau.VizManager.getVizs();" + 
						"return vizes.length" +
						"} return test();";		
		long len =  ((Number) executor.executeScript(vizLen)).longValue();	
		
		for(int i = 0; i < len; i++) {
			String wbSearch = "function test() {" +
							  "var vizes = tableau.VizManager.getVizs();" +
							  "var workbook = vizes[" + i + "].getWorkbook();" + 
							  "return workbook.getName()" +
							  "} return test();";
			String wbName = (String) executor.executeScript(wbSearch);
			if (wbName.contains(vizName)) {
				report.success("Message", "wbName[" + i + "]: " + wbName);
				index = i;
				break;
			}
		}
		return index;
	}	
	
	
	/**
	 * 
	 * @param index
	 * @param key
	 * @param value
	 */
	public void getDrillDownInt(int index, String key, long value) {
		JavascriptExecutor executor = (JavascriptExecutor) driver;		
		String drillAction= "var vizes = tableau.VizManager.getVizs();" +
				 			"var workbook = vizes[" + index + "].getWorkbook();" + 
				 			"var sheet = workbook.getActiveSheet();" +
				 			"sheet.selectMarksAsync(\"" + key + "\"," + value + ",tableau.SelectionUpdateType.ADD);";						
		executor.executeScript(drillAction);
	}	
	
	
	/**
	 * 
	 * @param index
	 * @param key
	 * @param value
	 */
	public void getDrillDownString(int index, String key, String value) {
		JavascriptExecutor executor = (JavascriptExecutor) driver;		
		String drillAction= "var vizes = tableau.VizManager.getVizs();" +
				 			"var workbook = vizes[" + index + "].getWorkbook();" + 
				 			"var sheet = workbook.getActiveSheet();" +
				 			"sheet.selectMarksAsync(\"" + key + "\",\"" + value + "\",tableau.SelectionUpdateType.ADD);";						
		executor.executeScript(drillAction);
	}	

	
	/**
	 * 
	 * @param index
	 * @param key
	 * @param value
	 */
	public void getCSV(int index, String key, long value) {
		JavascriptExecutor executor = (JavascriptExecutor) driver;		
		String getCSV=	"var vizes = tableau.VizManager.getVizs();" +
				 		"var workbook = vizes[" + (index + 1) + "].getWorkbook();" + 
				 		"var sheet = workbook.getActiveSheet();" +
				 		"workbook.changeParameterValueAsync(\"" + key + "\"," + value + ");";						
		executor.executeScript(getCSV);
	}	
	

	/**
	 * 
	 * @param obj
	 * @return
	 */
	public ArrayList<String> getDrillParam(By obj) {
		ArrayList<String> data = new ArrayList<String>();
		String[] temp;
		String str = null;
		List<WebElement> myElements;
		myElements = driver.findElements(obj);
		for(WebElement e : myElements) {
			str = e.getText();
		}		
		temp = str.split("\\r?\\n");
		for (int i = 0; i < temp.length; i++) {
			data.add(temp[i]);
		}		
		return data;
	}	
		

	/**
	 * 
	 * @param expectedData
	 * @param actualData
	 * @throws IOException 
	 */
	public boolean validateDrillParam(ArrayList<String> expectedData, ArrayList<String> actualData) throws IOException {
		Constants.moduleErrCounter = 0;
		boolean strFound = false;
		String actualDrillParam;
		if (expectedData.size() == actualData.size()) {		
			for (int i = 0; i < expectedData.size(); i++) {
				strFound = false;
				actualDrillParam = "";
				for (int j = 0; j < actualData.size(); j++) {
					String[] temp = (actualData.get(j)).split("\\:");
					actualDrillParam = temp[1].trim();
					if (temp[1].trim().equals(expectedData.get(i).trim())) {
						report.success("Matched", "[Drilldown Parameter] Expected Data (" + expectedData.get(i).trim() + ") :: Actual Data (" + temp[1].trim() + ")");
						strFound = true;
					}				
				}
				if (!strFound) {
					report.error("Not Matched", "[Drilldown Parameter] Expected Data (" + expectedData.get(i).trim() + ") :: Actual Data (" + actualDrillParam + ")");
				}
			}
		}
		else if(expectedData.size() > actualData.size()) {
			String tempData = "";
			String[] temp = (actualData.get(0)).split("\\:");
			actualDrillParam = temp[1].trim();
			for (int i = 0; i < expectedData.size(); i++) {
				if (i == 0) {
					tempData = expectedData.get(i);
				} else {
					tempData += " > " + expectedData.get(i);
				}
			}
			if (tempData.equals(actualDrillParam)) {
				report.success("Matched", "[Drilldown Parameter] Expected Data (" + tempData + ") :: Actual Data (" + actualDrillParam + ")");
			}
			else {
				report.error("Not Matched", "[Drilldown Parameter] Expected Data (" + tempData + ") :: Actual Data (" + actualDrillParam + ")");
			}
		}		
		else {
			report.error("Not Matched", "[Drilldown Parameter] Expected Data (" + expectedData + ") size is not matching with the Actual Data (" + actualData + ")");
		}
		return strFound;
	}		
	
	
	/**
	 * 
	 * @param obj
	 * @return 
	 */
	public ArrayList<String> getDrillVizzes(By obj) {
		ArrayList<String> data = new ArrayList<String>();
		String[] temp;
		String str = null;
		List<WebElement> myElements;
		myElements = driver.findElements(obj);
		for(WebElement e : myElements) {
			str = e.getText();
		}
		temp = str.split("\\r?\\n");
		for (int i = 0; i < temp.length; i++) {
			data.add(temp[i]);
		}		
		return data;
	}
	
	
	/**
	 * 
	 * @param expectedData
	 * @param actualData
	 * @throws IOException 
	 * @throws ParseException 
	 */
	public ArrayList<String> validateDrillVizList(ArrayList<String> expectedData, ArrayList<String> actualData) throws IOException, ParseException {
		boolean strFound = false;
		ArrayList<String> data = new ArrayList<String>();
		int index = 0;
		if (expectedData.size() == actualData.size()) {
			for (int i = 0; i < expectedData.size(); i++) {
				strFound = false;
				for (int j = 0; j < actualData.size(); j++) {
					if (expectedData.get(i).trim().equals(actualData.get(j).trim())) {
						report.success("Matched", "[Drilldown Menu] Expected Data (" + expectedData.get(i).trim() + ") :: Actual Data (" + actualData.get(j).trim() + ")");
						data.add(index, expectedData.get(i).trim());
						index++;
						strFound = true;
					}				
				}
				if (!strFound) {
					report.error("Not Matched", "[Drilldown Menu] Expected Data (" + expectedData.get(i).trim() + ") is present not in the current drill down list");
				}
			}
		} else {
			report.error("Not Matched", "[Drilldown Menu] Expected Data (" + expectedData + ") size is not matching with the Actual Data (" + actualData + ")");
		}
		if (Base.getBooleanConfigData("executeRegression")) report.updateModuleReportDrillDownMenuValidationSteps();
		return data;
	}
	
	
	/**
	 * This method used to get the applied filter values from the print preview page
	 * @return
	 */
	public Map<String, String> extractFilterDataFromPrintPage() {
		Map<String, String> map = new HashMap<String, String>(); 
		List<WebElement> printTextElements=driver.findElements(By.xpath("//div[@class='printVizPage-style']/span"));	
	
		for(int j=0; j<printTextElements.size(); j++) {
			if(!(printTextElements.get(j).getText()).isEmpty()) {
				String[] data = printTextElements.get(j).getText().replace("|", "").split(":");
				if (data[0].equalsIgnoreCase("dates")) {
					String pattern = "(\\()(.)+(\\))";
					Pattern r = Pattern.compile(pattern);
					Matcher m = r.matcher(data[1]);
					String fullDate = null;
					if (m.find()) fullDate=m.group(0).replace("(", "").replace(")", "");
					String[] arrOfStr = fullDate.split(" - "); 
					String startDate=getDateFormatMMDDYYYY(arrOfStr[0]);
					String endDate=getDateFormatMMDDYYYY(arrOfStr[1]);
					map.put("DateRange", data[1].split("\\(")[0].trim());
					map.put("StartDate", startDate);
					map.put("EndDate", endDate );
				} else {
					map.put(data[0].replace(" ", ""), data[1].replace(" ", ""));
				}
			}
		}
		return map;
	}
	
	
	/**
	 * This method return the string date in month/day/year format 
	 * @param date : the input string date format is year-month-day
	 * @return
	 */
	public String getDateFormatMMDDYYYY(String date) {
		String[] dateArray=date.split("-");
		return dateArray[1]+"/"+dateArray[2]+"/"+dateArray[0];
	}
	
}
