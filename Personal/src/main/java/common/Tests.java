package common;

import java.awt.AWTException;
import java.awt.Robot;
import java.awt.event.InputEvent;
import java.io.IOException;
import java.sql.SQLException;
import java.text.ParseException;
import java.util.ArrayList;
import java.util.LinkedHashMap;

import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;

import config.Constants;
import pages.VizPage;

public class Tests {
	
	public void drillDownAndUIChecks() throws IOException, InterruptedException, ParseException, SQLException, AWTException {
		Base.setProperty("test", "regression");
    	Report report = new Report();
		CsvHandlers tp = new CsvHandlers();    	
    	
		report.beforeTest();
		
		ArrayList<LinkedHashMap<String, String>> testPlan = new ArrayList<LinkedHashMap<String, String>>(tp.readTestPlan(Constants.testPlan()));
    	if (testPlan.size() > 0) {
			for (int loop = 0; loop < testPlan.size(); loop++) {
		        if (testPlan.get(loop).get("EXECUTE").equals("1") && testPlan.get(loop).get("CLIENT").equals(Base.getStringConfigData("client"))) {
	
		        	String dashboardName = testPlan.get(loop).get("DASHBOARDNAME");
		        	String baseLevelVizName = tp.vizMap(testPlan.get(loop).get("VIZNAME")) != null ? tp.vizMap(testPlan.get(loop).get("VIZNAME")) : testPlan.get(loop).get("VIZNAME");    	
	
		        	Constants.errFlag = false;
		        	Database db  = new Database();
		        	if (db.verifyDashVizExistsInDb(dashboardName, baseLevelVizName)) {	   
		        		
			        	String firstLevelVizName = "NA";
			        	String secondLevelVizName = "NA";
			        	report.initTestReport(dashboardName, baseLevelVizName);
	
						String dataSQLLabel = "Data" + "_" + "BaseLevel" + "_" + dashboardName + "_" + baseLevelVizName + "_" + firstLevelVizName + "_" + secondLevelVizName;					
				
						if (Boolean.parseBoolean(db.executeSQL(dataSQLLabel).get(0))) {
							
				        	report.updateModuleReportDashViz(dashboardName, baseLevelVizName, firstLevelVizName, secondLevelVizName);
				        	WebDriver driver;
							Base b = new Base();
							driver = b.initDriver();
							report.success("Action", "[Connectivity] Connection Established");
							
							Modules test = new Modules(driver);	
							Common func = new Common(driver);
							Sync wait = new Sync(driver);
							VizPage viz = new VizPage(driver);
							DataValidation data = new DataValidation(driver);
							Filters filter = new Filters(driver);
	
							if (!test.appLaunchSteps(dashboardName)) break;
							if (Base.getBooleanConfigData("needContextualCheck")) {
								test.checkContextualMenu(dashboardName, baseLevelVizName);
							}						
		        		
							filter.setDefaultFilters();
							
							if (test.getViz(baseLevelVizName)) {	
								report.updateModuleReportGetVizSteps();
								if (test.getVizView("Table")) {
									if (test.getVizView("Both")) {									
									
										report.updateModuleReportVizViewSteps();
										if (Base.getBooleanConfigData("needExportAllCSV")) {
											test.exportAllCSVChecks(baseLevelVizName);
										}
										
										if (Base.getBooleanConfigData("needDataValidationCheck") && Boolean.parseBoolean(db.executeSQL(dataSQLLabel).get(0))) {
											if (data.dataValidation(baseLevelVizName, dataSQLLabel)) report.cleanDirectory(Constants.downloadPath);
											//else break;
										}
										
										if (Base.getBooleanConfigData("needFirstLevelDrillChecks")) {									
											ArrayList<String> expectedBaseLevelDrillDownList = new ArrayList<String>();
											ArrayList<String> sqlParams =  new ArrayList<String>();
											ArrayList<String> expectedDrillParamData = new ArrayList<String>();
											boolean isBaseLevelValueDTInteger, isBaseLevelValueDTString, isFirstLevelValueDTInteger, isFirstLevelValueDTString;
											long baseLevelValueInteger, firstLevelValueInteger;
											String baseLevelValueString, firstLevelValueString, baseKey, baseValueDataType, firstLevelKey, firstLevelValueDataType;	
											int index;
			
											expectedBaseLevelDrillDownList = db.getDrillDownListFromDb(baseLevelVizName);										
									
											if (expectedBaseLevelDrillDownList != null) {
												
												String paramSQLLabel = "Param" + "_" +  "BaseLevel" + "_" + dashboardName + "_" + baseLevelVizName + "_" + firstLevelVizName + "_" + secondLevelVizName;
												
												if (db.getSQL(paramSQLLabel) != "" && Boolean.parseBoolean(db.executeSQL(paramSQLLabel).get(0))) {	
													
													index = 1;			
													isBaseLevelValueDTInteger = false;
													isBaseLevelValueDTString = false;
													baseLevelValueInteger = 0;
													baseLevelValueString = null;
													baseKey = db.getDrillDownParamKeyFromDb(baseLevelVizName);
													baseValueDataType = db.getDrillDownParamValueDataTypeFromDb(paramSQLLabel);
													
													if (baseValueDataType.equals("int")) {
														baseLevelValueInteger = db.getDrillDownParamValueIntIdFromDb(paramSQLLabel);
														isBaseLevelValueDTInteger = true;
													} else {
														baseLevelValueString = db.getDrillDownParamValueStringIdFromDb(paramSQLLabel);
														isBaseLevelValueDTString = true;
													}
													
													for(int baseLevelIterator = 1; baseLevelIterator <= expectedBaseLevelDrillDownList.size(); baseLevelIterator++) {
														
														if (isBaseLevelValueDTInteger) func.getDrillDownInt(index, baseKey, baseLevelValueInteger);
														if (isBaseLevelValueDTString) func.getDrillDownString(index, baseKey, baseLevelValueString);					
														wait.waitUntilObjectLoad(viz.txtDrillParam());
														
														if (baseLevelIterator == 1) {
															if (isBaseLevelValueDTInteger) sqlParams.add(db.addToArrayList(baseKey, String.valueOf(baseLevelValueInteger), "int"));
															if (isBaseLevelValueDTString) sqlParams.add(db.addToArrayList(baseKey, String.valueOf(baseLevelValueString), "string"));
															expectedDrillParamData.add(db.getDrillDownParamValueNameFromDb(paramSQLLabel));	
															func.validateDrillParam(expectedDrillParamData, func.getDrillParam(viz.txtDrillParam()));
															func.validateDrillVizList(expectedBaseLevelDrillDownList, func.getDrillVizzes(viz.linkDrillViz()));
														}
														
														boolean baseLevelDrillDownListMatchFound = false;
														for (int i = 0; i < expectedBaseLevelDrillDownList.size(); i++) {
															
															if (expectedBaseLevelDrillDownList.get(i).equalsIgnoreCase(func.getElement(By.cssSelector("#drillDownModal > div > div > div.modal-body.drilldown-menu-div > ul.lu-drilldown-visualizations > li:nth-child(" + baseLevelIterator + ") > a > span")).getText())) {
																baseLevelDrillDownListMatchFound = true;
																func.getElement(By.cssSelector("#drillDownModal > div > div > div.modal-body.drilldown-menu-div > ul.lu-drilldown-visualizations > li:nth-child(" + baseLevelIterator + ") > a > span")).click();													
														    	report.success("Action", "[Navigation] Base Level Viz: " + baseLevelVizName + " ---> Drill Down Viz: " + expectedBaseLevelDrillDownList.get(i));	
														    	Thread.sleep(500);
	
																firstLevelVizName = expectedBaseLevelDrillDownList.get(i);
													        	secondLevelVizName = "NA";
													        	report.updateModuleReportDashViz(dashboardName, baseLevelVizName, firstLevelVizName, secondLevelVizName);
													        	
																if (test.getVizView("Chart")) {
																	if (test.getVizView("Table")) {
																		if (!test.getVizView("Both")) break;
																	} else break;																	
																} else break;
																
																report.updateModuleReportVizViewSteps();
																dataSQLLabel = "Data" + "_"  + "FirstLevel" + "_" + dashboardName + "_" + baseLevelVizName + "_" + firstLevelVizName + "_" + secondLevelVizName;
																
																if (Boolean.parseBoolean(db.executeSQL(dataSQLLabel).get(0))) {
																	
																	if (Base.getBooleanConfigData("needDataValidationCheck") && Boolean.parseBoolean(db.executeSQL(dataSQLLabel).get(0))) {
																		data.dataValidation(firstLevelVizName, db.createArrayList(dataSQLLabel, sqlParams));
																		report.cleanDirectory(Constants.downloadPath);
																	}
																	if (Base.getBooleanConfigData("needPrintPreviewCheck")) {
																		test.getPrint(); 
																		test.verifyPrintDrillParam(expectedDrillParamData);
																		report.updateModuleReportPrintPreviewSteps();
																	}
																	report.updateModuleSummaryLogs("BreadCrumbNavigationSteps", "NA");
																	
																	if (Base.getBooleanConfigData("needSecondLevelDrillChecks")) {
																		ArrayList<String> expectedFirstLevelDrillDownList =  new ArrayList<String>();
																		expectedFirstLevelDrillDownList = db.getDrillDownListFromDb(firstLevelVizName);	
																		
																		if (expectedFirstLevelDrillDownList != null){
																			
																			paramSQLLabel = "Param" + "_"  + "FirstLevel" + "_" + dashboardName + "_" + baseLevelVizName + "_" + firstLevelVizName + "_" + secondLevelVizName;
																			
																			if (db.getSQL(paramSQLLabel) != "" && Boolean.parseBoolean(db.executeSQL(paramSQLLabel).get(0))) {	
																				
																				isFirstLevelValueDTInteger = false;
																				isFirstLevelValueDTString = false;
																				firstLevelValueInteger = 0;
																				firstLevelValueString = null;
																				firstLevelKey = db.getDrillDownParamKeyFromDb(firstLevelVizName);
																				firstLevelValueDataType = db.getDrillDownParamValueDataTypeFromDb(db.createArrayList(paramSQLLabel, sqlParams));																
																				if (firstLevelValueDataType.equals("int")) {
																					firstLevelValueInteger = db.getDrillDownParamValueIntIdFromDb(db.createArrayList(paramSQLLabel, sqlParams));
																					isFirstLevelValueDTInteger = true;
																				} else {
																					firstLevelValueString = db.getDrillDownParamValueStringIdFromDb(db.createArrayList(paramSQLLabel, sqlParams));
																					isFirstLevelValueDTString = true;
																				}
				
																				for(int firstLevelIterator = 1; firstLevelIterator <= expectedFirstLevelDrillDownList.size(); firstLevelIterator++) {	
																					
																					if (firstLevelIterator==1) expectedDrillParamData.add(db.getDrillDownParamValueNameFromDb(db.createArrayList(paramSQLLabel, sqlParams)));
																					if(isFirstLevelValueDTInteger) func.getDrillDownInt(index, firstLevelKey, firstLevelValueInteger);
																					if (isFirstLevelValueDTString) func.getDrillDownString(index, firstLevelKey, firstLevelValueString);
																					wait.waitUntilObjectLoad(viz.txtDrillParam());
																					
																					if (firstLevelIterator==1) {
																						if (isFirstLevelValueDTInteger) sqlParams.add(db.addToArrayList(firstLevelKey, String.valueOf(firstLevelValueInteger), "int"));
																						if (isFirstLevelValueDTString) sqlParams.add(db.addToArrayList(firstLevelKey, firstLevelValueString, "string"));
																						func.validateDrillParam(expectedDrillParamData, func.getDrillParam(viz.txtDrillParam()));
																						func.validateDrillVizList(expectedFirstLevelDrillDownList, func.getDrillVizzes(viz.linkDrillViz()));
																					}
				
																					boolean firstLevelDrillDownListMatchFound = false;
																					for (int j = 0; j < expectedFirstLevelDrillDownList.size(); j++) {
																						
																						if (expectedFirstLevelDrillDownList.get(j).equalsIgnoreCase(func.getElement(By.cssSelector("#drillDownModal > div > div > div.modal-body.drilldown-menu-div > ul.lu-drilldown-visualizations > li:nth-child(" + firstLevelIterator + ") > a > span")).getText())) {
																							
																							firstLevelDrillDownListMatchFound = true;
																							
																							func.getElement(By.cssSelector("#drillDownModal > div > div > div.modal-body.drilldown-menu-div > ul.lu-drilldown-visualizations > li:nth-child(" + firstLevelIterator + ") > a > span")).click();																				
																					    	report.success("Action", "[Navigation] First Level Viz: " + firstLevelVizName + " ---> Drill Down Viz: " + expectedFirstLevelDrillDownList.get(j));
																					    	Thread.sleep(500);	
																					    	
																							secondLevelVizName = expectedFirstLevelDrillDownList.get(j);	
																				        	report.updateModuleReportDashViz(dashboardName, baseLevelVizName, firstLevelVizName, secondLevelVizName);
																				        	
																							if (test.getVizView("Chart")) {
																								if (test.getVizView("Table")) {
																									if (!test.getVizView("Both")) break;
																								} else break;																	
																							} else break;
	
																							report.updateModuleReportVizViewSteps();
																					    	dataSQLLabel = "Data" + "_"  + "SecondLevel" + "_" + dashboardName + "_" + baseLevelVizName + "_" + firstLevelVizName + "_" + secondLevelVizName;
																							
																							if (Boolean.parseBoolean(db.executeSQL(dataSQLLabel).get(0))) {
					
																								if (Base.getBooleanConfigData("needDataValidationCheck") && Boolean.parseBoolean(db.executeSQL(dataSQLLabel).get(0))) {
																									data.dataValidation(secondLevelVizName, db.createArrayList(dataSQLLabel, sqlParams));
																									report.cleanDirectory(Constants.downloadPath);
																								}
																								if (Base.getBooleanConfigData("needPrintPreviewCheck")) {
																									test.getPrint(); 
																									test.verifyPrintDrillParam(expectedDrillParamData);
																									report.updateModuleReportPrintPreviewSteps();
																								}
																								
																								report.updateModuleSummaryLogs("DrillDownMenuValidationSteps", "NA");
																								
				//																				if (db.getDrillDownListFromDb(secondLevelVizName) != null){
				//																					paramSQLLabel = "Param" + "_"  + "SecondLevel" + "_" + dashboardName + "_" + baseLevelVizName + "_" + firstLevelVizName + "_" + secondLevelVizName;
				//																					if (db.getClientSQL(paramSQLLabel) != null && db.executeClientSQL(paramSQLLabel)) {
				//																						
				//																						/**
				//																						 * Placeholder for thirdlevel viz validation, if needed.... 
				//																						 */
				//																						
				//																					}
				//																					else {
				//																				    	report.warning("Message", "Parameter SQL not exists for second level viz (" + secondLevelVizName + ")");
				//																					}																				
				//																				}																			
																							}
																							else {
																						    	report.warning("Message", "Data validation turned OFF or Data SQL not exists for second level viz (" + secondLevelVizName + ")");
																						    	report.updateModuleSummaryLogs("DataValidationSteps", "OFF");
																							}
																							break;
																						}
																					}
																					if (!firstLevelDrillDownListMatchFound) {
																						String firstDrillDownListItem = func.getElement(By.cssSelector("#drillDownModal > div > div > div.modal-body.drilldown-menu-div > ul.lu-drilldown-visualizations > li:nth-child(" + firstLevelIterator + ") > a > span")).getText();
																						report.error("Message", "First Level Drilldown List Item from Actual (" + firstDrillDownListItem + ") is not matching with Expected. Hence not able to proceed with ("  + firstDrillDownListItem + ") drill down validations..");
																						Thread.sleep(2500);
																						Robot robot = new Robot();
																					    robot.mouseMove(800,175);
																					    robot.mousePress(InputEvent.BUTTON1_DOWN_MASK);
																					    robot.mouseRelease(InputEvent.BUTTON1_DOWN_MASK);
																					}
																					if (firstLevelDrillDownListMatchFound) {
																						test.navigateBreadCrumb(3);
																					}
																				}
																				if (sqlParams.size() == 2) sqlParams.remove(sqlParams.size()-1);
																				if (expectedDrillParamData.size() == 2) expectedDrillParamData.remove(expectedDrillParamData.size()-1);																
																			}														
																			else {
																		    	report.warning("Message", "Drilldown validation turned OFF or Param SQL not exists for first level viz (" + firstLevelVizName + ")");
																		    	report.updateModuleSummaryLogs("DrillDownMenuValidationSteps", "OFF");
																			}
																		} 
																		else {
																			report.updateModuleSummaryLogs("DrillDownMenuValidationSteps", "NA");
																		}
																	}
																	else {
																		report.updateModuleSummaryLogs("DrillDownMenuValidationSteps", "NA");
																	}
																}
																else {
															    	report.warning("Message", "Data validation turned OFF or Data SQL not exists for first level viz (" + firstLevelVizName + ")");
															    	report.updateModuleSummaryLogs("DataValidationSteps", "OFF");
																}
																break;
															}
														}
														if (!baseLevelDrillDownListMatchFound) {
															String baseDrillDownListItem = func.getElement(By.cssSelector("#drillDownModal > div > div > div.modal-body.drilldown-menu-div > ul.lu-drilldown-visualizations > li:nth-child(" + baseLevelIterator + ") > a > span")).getText();
															report.error("Message", "Base Level Drilldown List Item from Actual (" + baseDrillDownListItem + ") is not matching with Expected.. Hence not able to proceed with ("  + baseDrillDownListItem + ") drill down validations..");
															Thread.sleep(2500);
															Robot robot = new Robot();
														    robot.mouseMove(800,175);
														    robot.mousePress(InputEvent.BUTTON1_DOWN_MASK);
														    robot.mouseRelease(InputEvent.BUTTON1_DOWN_MASK);
														}
														if (baseLevelDrillDownListMatchFound) {
															if (!test.navigateBreadCrumb(2)) break;
														}
													}	
												}
												else {
											    	report.warning("Message", "Drilldown validation turned OFF or Param SQL not exists for base viz (" + baseLevelVizName + ")");
											    	report.updateModuleSummaryLogs("DrillDownMenuValidationSteps", "OFF");
												}								
											}
											else {
												report.updateModuleSummaryLogs("DrillDownMenuValidationSteps", "NA");										
											}
										}
									}
								}
							}
							test.quit();
						}
						else {
					    	report.warning("Message", "Execution turned OFF or Data SQL not exists for base viz (" + baseLevelVizName + ")");
					    	report.updateModuleSummaryLogs("DataValidationSteps", "OFF");
						}
			        	report.updateReportResult();  
		        	}
		        	else {
		        		Constants.errFlag = true;
		        		break;
		        	}
		        }
		        
			}
			report.afterTest();
    	}
	}
	
	
	/**
	 * Global & Saved Filters
	 * @throws IOException
	 * @throws InterruptedException
	 * @throws ParseException
	 * @throws SQLException
	 * @throws AWTException
	 */
	public void globalFilterChecks() throws IOException, InterruptedException, ParseException, SQLException, AWTException {
		
		Base b = new Base();
		if (Base.getBooleanConfigData("needSavedFiltersCheck") || Base.getBooleanConfigData("needGlobalFiltersCheck")) {
		
			boolean savedFilterExecutionFlag = false;
        	WebDriver driver;
			
			Base.setProperty("test", "filters");		
	    	Report report = new Report();
	    	CsvHandlers tp = new CsvHandlers();
	    	
			report.beforeTest();			
	    	
			ArrayList<LinkedHashMap<String, String>> testPlan = new ArrayList<LinkedHashMap<String, String>>(tp.readTestPlan(Constants.testPlan()));
	    	if (testPlan.size() > 0) {
				for (int loop = 0; loop < testPlan.size(); loop++) {
			        if (testPlan.get(loop).get("EXECUTE").equals("1") && testPlan.get(loop).get("CLIENT").equals(Base.getStringConfigData("client"))) {
		
			        	String dashboardName = testPlan.get(loop).get("DASHBOARDNAME");
			        	String baseLevelVizName = tp.vizMap(testPlan.get(loop).get("VIZNAME")) != null ? tp.vizMap(testPlan.get(loop).get("VIZNAME")) : testPlan.get(loop).get("VIZNAME");    	

			        	Database db  = new Database();
			        	if (db.verifyDashVizExistsInDb(dashboardName, baseLevelVizName)) {	        		
		
				        	report.initTestReport(dashboardName, baseLevelVizName);	
							String dataSQLLabel = "Data" + "_" + "BaseLevel" + "_" + dashboardName + "_" + baseLevelVizName;
							ArrayList<String> savedFilters = new ArrayList<String>();
							savedFilters.add(0, "automation");
							savedFilters.add(1, "editAutomation");
	
							
							/**
							 * Prerequisites
							 */
							if (Base.getBooleanConfigData("needSavedFiltersCheck") && !savedFilterExecutionFlag) {
								driver = b.initDriver();
								report.success("Action", "[Connectivity] Connection Established");
								
								Modules test = new Modules(driver);	
								Filters filter = new Filters(driver);	
								
								if (!test.appLaunchSteps(dashboardName)) break;
								filter.deleteIfCustomSavedFilterExists(savedFilters);
								test.quit();
							}
							
	
							/**
							 * Saved filters
							 */
							if (Base.getBooleanConfigData("needSavedFiltersCheck") && !savedFilterExecutionFlag) {
								driver = b.initDriver();
								report.success("Action", "[Connectivity] Connection Established");
								
								Modules test = new Modules(driver);	
								Filters filter = new Filters(driver);	
								Common func = new Common(driver);
	
								if (!test.appLaunchSteps(dashboardName)) break;
								if (!filter.setCustomFilters()) break; 
								if (test.getViz(baseLevelVizName)) {
									if (test.createSavedFilter(savedFilters.get(0), "This filter is created via automation testing", true)) {
										if (test.getVizView("Table")) {
											if (test.getVizView("Both")) {	
												test.getPrint();
												test.verifySavedFiltersData(db.getFormatedSaveFilterData(), func.extractFilterDataFromPrintPage());
												if (driver.findElement(By.cssSelector("#athena > div > div.page-header.hidden-print > span.pageTitleStyle")).isDisplayed()){
													driver.navigate().back();
												}
												Thread.sleep(1000);
												test.editSavedFilter(savedFilters.get(1), "This filter is edited via automation testing", true);
												test.deleteSavedFilter(savedFilters.get(1), true);
												savedFilterExecutionFlag = true;
											}
										}					
									}
									test.quit();
								}	
								else {
							    	report.error("Message", "Base Viz: (" + baseLevelVizName + ") is not loading");
								}								
							}
							
							
							/**
							 * Global filters
							 */
							if (Base.getBooleanConfigData("needGlobalFiltersCheck")) {	
								if (db.getSQL(dataSQLLabel) != "") {
									if (Boolean.parseBoolean(db.executeSQL(dataSQLLabel).get(0))) {
										driver = b.initDriver();
										report.success("Action", "[Connectivity] Connection Established");
										
										Modules test = new Modules(driver);	
										DataValidation data = new DataValidation(driver);
										Filters filter = new Filters(driver);	
		
										if (!test.appLaunchSteps(dashboardName)) break;
										filter.setCustomFilters();
										if (test.getViz(baseLevelVizName)) {
											if (test.getVizView("Table")) {
												if (test.getVizView("Both")) {	
													if (Base.getBooleanConfigData("needDataValidationCheck")) {
														if (data.dataValidation(baseLevelVizName, dataSQLLabel)) report.cleanDirectory(Constants.downloadPath);
														//else break;
													}
												}
												else {
											    	report.error("Message", "Both table and chart view is not loading. Not able to proceed drill down and data validations");
												}						
											}
											else {
										    	report.error("Message", "Table view is not loading. Not able to proceed data validations..");
											}
										}
										else {
									    	report.error("Message", "Base Viz: (" + baseLevelVizName + ") is not loading");
										}								
										test.quit();
									}
									else {
								    	report.warning("Message", "Execution turned OFF for base viz (" + baseLevelVizName + ")");
									}
								}	
								else {
							    	report.warning("Message", "Data SQL not exists in the folder for (" + dashboardName + " -> " + baseLevelVizName + ")");
								}
							}
				        	report.updateReportResult();
						}			        	
			        }
					if (!Base.getBooleanConfigData("needGlobalFiltersCheck") && savedFilterExecutionFlag) break;
				}
				report.afterTest();
			}
		}	
	}
}
