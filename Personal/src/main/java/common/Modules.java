package common;

import java.awt.AWTException;
import java.awt.Robot;
import java.awt.event.InputEvent;
import java.io.IOException;
import java.sql.SQLException;
import java.text.ParseException;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.NoSuchElementException;
import java.util.Set;

import org.openqa.selenium.By;
import org.openqa.selenium.JavascriptExecutor;
import org.openqa.selenium.NoSuchWindowException;
import org.openqa.selenium.StaleElementReferenceException;
import org.openqa.selenium.TimeoutException;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.support.ui.Select;

import config.Constants;
import pages.ClientSelectorPage;
import pages.DashboardPage;
import pages.FiltersPage;
import pages.HomePage;
import pages.LoginPage;
import pages.MenuPage;
import pages.VizPage;

public class Modules extends Base{
	
	public WebDriver driver;
	ArrayList<String> data = new ArrayList<String>();
	Common func;
	Sync wait;
	HomePage home;
	MenuPage menu;
	DashboardPage dash;
	FiltersPage filterObj;
	LoginPage login;
	VizPage viz;
	ClientSelectorPage client;
	Report report;
	Database db;
	DataValidation dataValidation;

	public Modules(WebDriver driver) throws IOException {
		this.driver = driver;	
		this.func = new Common(driver);
		this.login = new LoginPage(driver);
		this.home = new HomePage(driver);
		this.client = new ClientSelectorPage(driver);
		this.wait = new Sync(driver);
		this.dash = new DashboardPage(driver);
		this.filterObj= new FiltersPage(driver);
		this.menu = new MenuPage(driver);
		this.viz = new VizPage(driver);
		this.dataValidation = new DataValidation(driver);
    	this.report = new Report();
    	this.db = new Database();
	}
	
	
	/**
	 * 
	 * @throws IOException
	 * @throws InterruptedException
	 * @throws ParseException 
	 */
	public boolean appLaunchSteps(String dashboardName) throws IOException, InterruptedException, ParseException {	
		Constants.moduleErrCounter = 0;
		if (!launchUrl()) return false; 
		if (!getlogin()) return false;
		if (!getApplicationHome()) return false;
		if (!getClient()) return false;
		if (!getDashboardMenu()) return false;
		if (!getDashboard(dashboardName)) return false;
		if (getBooleanConfigData("executeRegression")) report.updateModuleReportAppLaunchSteps();
		return true;
	}	

	
	/**
	 * 
	 * @throws IOException
	 * @throws InterruptedException
	 */
	public boolean launchUrl() throws IOException, InterruptedException {	
		try {
			data = envCreds();		
			driver.get(data.get(0));
			if (wait.waitUntilObjectLoad(login.txtUsername())){
				report.success("Action", "[AppLaunch] Launched url: "  + data.get(0));
				report.success("Action", "[Navigation] Navigated into login page");
				return true;				
			}
		} catch (NullPointerException e) {
			report.error("Message", "Object not found");
		} 
		report.error("Message", "[AppLaunch] Failed to Launch the url: "  + data.get(0));
		return false;
	}	
	
	
	/**
	 * 
	 * @throws IOException
	 * @throws InterruptedException
	 */
	public boolean getlogin() throws IOException, InterruptedException {			
		try {
			data = envCreds();
			func.getElement(login.txtUsername()).sendKeys(data.get(1));		
			func.getElement(login.txtPassword()).sendKeys(data.get(2));
			func.getElement(login.btnLogin()).click();	
			if (wait.waitUntilObjectLoad(home.linkAppHome())){
		    	report.success("Action", "[Navigation] Navigated into Application Home Page");
				return true;
			}
		} catch (NullPointerException e) {
			report.error("Message", "Object not found");
		}
		report.error("Message", "[Navigation] Failed to Login");
		return false;
	}	
	
	
	/**
	 * 
	 * @throws IOException
	 * @throws InterruptedException
	 */
	public boolean getApplicationHome() throws IOException, InterruptedException {
		try {
			func.getElement(home.linkAppHome()).click();
			if (wait.waitUntilObjectLoad(client.linkClientSelector())){
		    	report.success("Action", "[Navigation] Navigated into client selector page");
				return true;
			}
		} catch (NullPointerException e) {
			report.error("Message", "Object not found");
		}
		report.error("Message", "[Navigation] Failed to navigate into client selector page");
		return false;
	}	
	
	
	/**
	 * 
	 * @throws IOException
	 * @throws InterruptedException
	 */
	public boolean getClient() throws IOException, InterruptedException {
		try {
			data = envCreds();
			func.getElement(client.linkClientSelector()).click();
			Select clientList= new Select(func.getElement(client.listClientSelector()));
			clientList.selectByValue(data.get(3));
	    	report.success("Action", "[Navigation] Selected Client (" + data.get(3) + ")");
			if (VerifyIfDashboardLoads()) {
				return true;
			}
		} catch (NullPointerException e) {
			report.error("Message", "Object not found");
		} catch (IndexOutOfBoundsException e) {
			report.error("Message", "[Navigation] Client (" + data.get(3) + ") not exists in the Client Selector");
		} catch (NoSuchElementException e) {
			report.error("Message", "[Navigation] Client (" + data.get(3) + ") not exists in the Client Selector");
		} 		
		report.error("Message", "[Navigation] Failed to select client (" + data.get(3) + ")");
		return false;
	}	
	
	
	/**
	 * 
	 * @throws IOException
	 * @throws InterruptedException
	 */
	public boolean VerifyIfDashboardLoads() throws IOException, InterruptedException {
		if (wait.waitUntilDashboardLoad(dash.dashVizzes())) {
	    	report.success("Message", "[Navigation] Dashboard Loaded: " + true);
			return true;
		} 
		else {
	    	report.error("Message", "[Navigation] Dashboard Loaded: " + false);
			return false;
		}
	}	
	
	
	/**
	 * 
	 * @param dashboard
	 * @throws IOException
	 * @throws InterruptedException
	 */
	public boolean getDashboardMenu() throws IOException, InterruptedException {
		try {
			func.getElement(menu.btnMenu()).click();
			if (wait.waitUntilObjectLoad(menu.menuDashboard())) {
		    	report.success("Action", "[Navigation] Dashboards Menu Loaded");
				return true;
			}
		} catch (NullPointerException e) {
			report.error("Message", "Object not found");
			Constants.moduleErrCounter++;
		} 
		report.error("Message", "[Navigation] Failed to load Dashboards Menu");
		return false;
	}	
	
	
	/**
	 * 
	 * @param dashName
	 * @throws IOException
	 * @throws InterruptedException
	 */
	public boolean getDashboard(String dashName) throws IOException, InterruptedException {
		try {
			List<WebElement> dashboard = driver.findElements(menu.menuDashboard());
			for(int i = 2; i <= dashboard.size(); i++) {
				String actualDashName = func.getElement(By.cssSelector("#app > div > div.wk-react-app.main-navbar-container.wk-block-display-element > nav.navbar.navbar-default.menubar > div > ul.nav.navbar-nav.menubar-fixed-buttons > li.dropdown.open > div > div > div.mega-menu > ul > li:nth-child(1) > ul > li:nth-child(" + i + ")")).getText();
				if (actualDashName.equals(dashName)) {
					func.getElement(By.cssSelector("#app > div > div.wk-react-app.main-navbar-container.wk-block-display-element > nav.navbar.navbar-default.menubar > div > ul.nav.navbar-nav.menubar-fixed-buttons > li.dropdown.open > div > div > div.mega-menu > ul > li:nth-child(1) > ul > li:nth-child(" + i + ")")).click();
					if (VerifyIfDashboardLoads()) {
				    	report.success("Action", "[Navigation] Navigated into expected dashboard (" + dashName + ")");
						return true;
					}
				}
			}
		} catch (TimeoutException e) {
			report.error("Message", "TimeoutException occured: " + e.getMessage());
		} catch (NoSuchElementException e) {
			report.error("Message", "NoSuchElementException occured: " + e.getMessage());
		} catch (NullPointerException e) {
			report.error("Message", "Object not found");
		} 
		report.error("Message", "[Navigation] Failed to load expected dashboard (" + dashName + ")");
		return false;			
	}	
	
	
	/**
	 * 
	 * @param vizName
	 * @throws IOException
	 * @throws InterruptedException
	 * @throws ParseException 
	 */
	public boolean checkContextualMenu(String dashboard, String vizName) throws IOException, InterruptedException, ParseException {
		try {
			Constants.moduleErrCounter = 0;
			List<WebElement> elements = driver.findElements(dash.dashVizzes());
			for(int i = 1; i <= elements.size(); i++) {
				String actualVizName = func.getElement(By.cssSelector("#visualizations > div > div > div:nth-child(" + i + ") > div > div > div > div > div.col-md-12.card-title > a > div")).getText();
				if (actualVizName.equals(vizName)) {
					if (wait.waitUntilObjectLoad(By.cssSelector("#visualizations > div > div > div:nth-child(" + i + ") > div > div > div > div > div.col-md-12.card-title > div > div > a > span"))) {						
						driver.findElement(By.cssSelector("#visualizations > div > div > div:nth-child(" + i + ") > div > div > div > div > div.col-md-12.card-title > div > div > a > span")).click();
						if (wait.waitUntilObjectLoad(By.cssSelector("#visualizations > div > div > div:nth-child(" + i + ") > div > div > div > div > div.col-md-12.card-title > div > div > ul > li.descriptionTitle"))) {
					    	report.success("Action", "[Contextual Menu] Loaded for Viz: " + vizName);
							String actContextualVizName = driver.findElement(By.cssSelector("#visualizations > div > div > div:nth-child(" + i + ") > div > div > div > div > div.col-md-12.card-title > div > div > ul > li.descriptionTitle")).getText();
							if (vizName.equals(actContextualVizName)) {
						    	report.success("Action", "[Contextual Menu] Expected Viz: " + vizName + " :: Actual Viz: " + actContextualVizName);	
							}
							else {
						    	report.error("Action", "[Contextual Menu] Expected Viz: " + vizName + " :: Actual Viz: " + actContextualVizName);
							}
							
							String expDescription = db.verifyVizDescriptionInDb(dashboard, vizName);
							String actDescription = driver.findElement(By.cssSelector("#visualizations > div > div > div:nth-child(" + i + ") > div > div > div > div > div.col-md-12.card-title > div > div > ul > li:nth-child(2) > div > div > div.col-md-11 > div")).getText();		
							if (expDescription.equals(actDescription)) {
						    	report.success("Action", "[contextual Menu] Expected Description: " + expDescription + " :: Actual Description: " + actDescription);
							}
							else {
						    	report.error("Action", "[Contextual Menu] Expected Description: " + expDescription + " :: Actual Description: " + actDescription);
							}
						
							
							if (Base.getBooleanConfigData("needSubscriptionCheck")) {
								for (int j=10; j<11; j++) {
									wait.waitUntilObjectLoad(By.cssSelector("#visualizations > div > div > div:nth-child(" + i + ") > div > div > div > div > div.col-md-12.card-title > div > div > ul > li:nth-child(8) > a"));
									String optionsLabel = driver.findElement(By.cssSelector("#visualizations > div > div > div:nth-child(" + i + ") > div > div > div > div > div.col-md-12.card-title > div > div > ul > li:nth-child(8) > a")).getText();
									if (optionsLabel.equals("Subscription Options")) {								
										checkSubscription(i, j);
										Thread.sleep(1500);
									}
									else if(optionsLabel.equals("Unsubscribe")) {
										wait.waitUntilObjectLoad(By.cssSelector("#visualizations > div > div > div:nth-child(" + i + ") > div > div > div > div > div.col-md-12.card-title > div > div > ul > li:nth-child(8) > a"));
										driver.findElement(By.cssSelector("#visualizations > div > div > div:nth-child(" + i + ") > div > div > div > div > div.col-md-12.card-title > div > div > ul > li:nth-child(8) > a")).click();
										Thread.sleep(1000);
										
										wait.waitUntilObjectLoad(By.cssSelector("#visualizations > div > div > div:nth-child(" + i + ") > div > div > div > div > div.col-md-12.card-title > div > div > a > span"));
										driver.findElement(By.cssSelector("#visualizations > div > div > div:nth-child(" + i + ") > div > div > div > div > div.col-md-12.card-title > div > div > a > span")).click();
										Thread.sleep(1000);
										
										wait.waitUntilObjectLoad(By.cssSelector("#visualizations > div > div > div:nth-child(" + i + ") > div > div > div > div > div.col-md-12.card-title > div > div > ul > li.descriptionTitle"));
										checkSubscription(i, j);
										Thread.sleep(1500);
									}
									else {
								    	report.error("Action", "[Contextual Menu] Subscription is not working as expected");
										break;
									}
								}
							}
						}
					}
					else {
				    	report.error("Action", "[Contextual Menu] object not loaded");
					}
				}
			}	
		} catch (TimeoutException e) {
			report.error("Message", "TimeoutException occured: " + e.getMessage());
			return false;
		} catch (NoSuchElementException e) {
			report.error("Message", "NoSuchElementException occured: " + e.getMessage());
			return false;
		} catch (NullPointerException e) {
			report.error("Message", "Object not found");
			return false;
		} 
		if (getBooleanConfigData("executeRegression")) report.updateModuleReportContextualMenuSteps();
		return true;		
	}	

	
	/**
	 * 
	 * @param vizIterator
	 * @param radioIterator
	 * @throws IOException
	 * @throws InterruptedException
	 */
	public void checkSubscription(int vizIterator, int radioIterator) throws IOException, InterruptedException {
		
		wait.waitUntilObjectLoad(By.cssSelector("#visualizations > div > div > div:nth-child(" + vizIterator + ") > div > div > div > div > div.col-md-12.card-title > div > div > ul > label:nth-child(" + radioIterator + ")"));
		String options = driver.findElement(By.cssSelector("#visualizations > div > div > div:nth-child(" + vizIterator + ") > div > div > div > div > div.col-md-12.card-title > div > div > ul > label:nth-child(" + radioIterator + ")")).getText();

		wait.waitUntilObjectLoad(By.cssSelector("#visualizations > div > div > div:nth-child(" + vizIterator + ") > div > div > div > div > div.col-md-12.card-title > div > div > ul > label:nth-child(" + radioIterator + ") > input[type=radio]"));
		if (options.trim().equals("Daily")) {
			driver.findElement(By.cssSelector("#visualizations > div > div > div:nth-child(" + vizIterator + ") > div > div > div > div > div.col-md-12.card-title > div > div > ul > label:nth-child(" + radioIterator + ") > input[type=radio]")).click();
		}
		if (options.trim().equals("Weekly")) {
			driver.findElement(By.cssSelector("#visualizations > div > div > div:nth-child(" + vizIterator + ") > div > div > div > div > div.col-md-12.card-title > div > div > ul > label:nth-child(" + radioIterator + ") > input[type=radio]")).click();
		}
		if (options.trim().equals("Monthly")) {
			driver.findElement(By.cssSelector("#visualizations > div > div > div:nth-child(" + vizIterator + ") > div > div > div > div > div.col-md-12.card-title > div > div > ul > label:nth-child(" + radioIterator + ") > input[type=radio]")).click();
		}
		
		Thread.sleep(1000);
		wait.waitUntilObjectLoad(By.cssSelector("#visualizations > div > div > div:nth-child(" + vizIterator + ") > div > div > div > div > div.col-md-12.card-title > div > div > ul > li:nth-child(8) > a"));
		String optionsLabel = driver.findElement(By.cssSelector("#visualizations > div > div > div:nth-child(" + vizIterator + ") > div > div > div > div > div.col-md-12.card-title > div > div > ul > li:nth-child(8) > a")).getText();
		if (optionsLabel.equals("Unsubscribe")){
	    	report.success("Action", "[Contextual Menu] (" + options.trim() + ") subscription works fine");	
			driver.findElement(By.cssSelector("#visualizations > div > div > div:nth-child(" + vizIterator + ") > div > div > div > div > div.col-md-12.card-title > div > div > ul > li:nth-child(8) > a")).click();
		}
		else {
	    	report.error("Action", "[Contextual Menu] (" + options.trim() + ") subscription is not working as expected");
		}
	}
	
	
	/**
	 * 
	 * @param vizName
	 * @throws IOException
	 * @throws InterruptedException
	 * @throws ParseException 
	 */
	public boolean getViz(String vizName) throws IOException, InterruptedException {
		Constants.moduleErrCounter = 0;
		for (int a = 0; a < 2; a++) {			
			try {
				List<WebElement> elements = driver.findElements(dash.dashVizzes());
				for(int i = 1; i <= elements.size(); i++) {
					String actualVizName = func.getElement(By.cssSelector("#visualizations > div > div > div:nth-child(" + i + ") > div > div > div > div > div.col-md-12.card-title > a > div")).getText();
					if (actualVizName.equals(vizName)) {
						func.getElement(By.cssSelector("#visualizations > div > div > div:nth-child(" + i + ") > div > div > div > div > div.col-md-12.card-title > a > div")).click();
						if (wait.waitUntilChartLoad()) {
					    	report.success("Action", "[Navigation] Navigated into an expected viz (" + vizName + ")");
					    	report.success("Action", "[Views] Chart view is loading fine");
							return true;
						}
					}
				}	
			} catch (TimeoutException e) {
				report.error("Message", "TimeoutException occured: " + e.getMessage());
			} catch (NoSuchElementException e) {
				report.error("Message", "NoSuchElementException occured: " + e.getMessage());
			} catch (NullPointerException e) {
				report.error("Message", "Object not found");
			} catch (StaleElementReferenceException e) {
				if (a == 0) 
					report.warning("Message", "StaleElementReferenceException occurred. Giving (" + (a+1) + ") more try..");
				else
					report.error("Message", "StaleElementReferenceException occurred.");
			}
		}
    	report.error("Action", "[Navigation] (" + vizName + ") chart view failed to load");
		return false;		
	}	
	
	
	/**
	 * 
	 * @param vizView
	 * @throws IOException
	 * @throws InterruptedException
	 * @throws ParseException 
	 */
	public boolean getVizView(String vizView) throws IOException, InterruptedException, ParseException{
		Constants.moduleErrCounter = 0;
		try {
			func.getElement(viz.btnView()).click();
			if (vizView.equalsIgnoreCase("Chart")) {
				func.getElement(viz.listChart()).click();
				if (wait.waitUntilChartLoad()) {	
			    	report.success("Action", "[Views] Selected (" + vizView + ") View");
			    	report.success("Action", "[Views] Chart view is loading fine");
			    	return true;
				}
				else {
					report.error("Action", "[Views] (" + vizView + ") view failed to load.");
				}
			} 
			else if (vizView.equalsIgnoreCase("Table")){
				func.getElement(viz.listTable()).click();
				if (wait.waitUntilTableLoad()) {	
			    	report.success("Action", "[Views] Selected (" + vizView + ") View");
			    	report.success("Action", "[Views] Table view is loading fine");
			    	return true;
				}
				else {
					report.error("Action", "[Views] (" + vizView + ") view failed to load.");
				}
			} 
			else if (vizView.equalsIgnoreCase("Both")){
				func.getElement(viz.listBoth()).click();
				if (wait.waitUntilPageLoad()) {	
			    	report.success("Action", "[Views] Selected (" + vizView + ") View");
			    	report.success("Action", "[Views] Both view is loading fine");
			    	return true;
				}
				else {
					report.error("Action", "[Views] (" + vizView + ") view failed to load.");
				}
			}
		} catch (NullPointerException e) {
			report.error("Message", "Object not found");
		} 
		return false;
	}	
	
	
	/**
	 * 
	 * @param level
	 * @throws IOException 
	 * @throws ParseException 
	 */
	public boolean navigateBreadCrumb(int level) throws IOException, ParseException {
		Constants.moduleErrCounter = 0;
		try {			
			func.getElement(By.cssSelector("#athena > div > div.page-header.hidden-print > div.breadCrumbStyle > span:nth-child(" + level + ") > span.breadCrumbItem > a")).click();
			if (wait.waitUntilPageLoad()) {
				if(level == 3) {
			    	report.success("Action", "[Navigation] BreadCrumb: First Level <--- Second Level");
			    	if (getBooleanConfigData("executeRegression")) report.updateModuleReportBreadCrumbNavigationSteps();
					return true;
				} else if (level == 2){
			    	report.success("Action", "[Navigation] BreadCrumb: Base Level <--- First Level");
			    	if (getBooleanConfigData("executeRegression")) report.updateModuleReportBreadCrumbNavigationSteps();
					return true;
				}				
			}
		} catch (NullPointerException e) {
			report.error("Message", "Object not found");
		} 
		if (getBooleanConfigData("executeRegression")) report.updateModuleReportBreadCrumbNavigationSteps();
		return false;
	}
	
	
	/**
	 * 
	 * @return
	 * @throws InterruptedException
	 * @throws AWTException 
	 * @throws IOException 
	 */
	public boolean getPrint() throws InterruptedException, AWTException, IOException{
		Constants.moduleErrCounter = 0;
		JavascriptExecutor executor = (JavascriptExecutor) driver;
		Set<String> ids;
		Iterator<String> it;
		String parentId;
		String childId;
		try {			
			for (int i = 0; i < 2; i++) {
				Thread.sleep(500);
				func.getElement(viz.btnPrint()).click();
				for(int m = 0; m < 120; m++) {
					ids = driver.getWindowHandles();
					if (ids.size() == 2) {
						it = ids.iterator();
						parentId = it.next();
						childId = it.next();
						driver.switchTo().window(childId);	
						Thread.sleep(2000);
						executor.executeScript("document.querySelector(\"print-preview-app\").shadowRoot.querySelector(\"print-preview-sidebar\").shadowRoot.querySelector(\"print-preview-button-strip\").shadowRoot.querySelector(\"cr-button.cancel-button\").click();");							
						driver.switchTo().window(parentId);
				    	report.success("Message", "[Print] Print preview dialog loaded");
						return true;
					} 
					else 
						Thread.sleep(1000);
				}		
				Robot robot = new Robot();
			    robot.mouseMove(800,175);
			    robot.mousePress(InputEvent.BUTTON1_DOWN_MASK);
			    robot.mouseRelease(InputEvent.BUTTON1_DOWN_MASK);
			    report.warning("Message", "[Print] Print preview dialog is not loading in (" + (i + 1) + ") attempt.");
			}			
		} catch (NullPointerException e) {
			report.error("Message", "[Print] Object not found");
		} catch (NoSuchWindowException e) {
			report.error("Message", "NoSuchWindowException occured: " + e.getMessage());
		}
	    report.error("Message", "[Print] Print preview dialog is not loading.");
		return false;	
	}
	
	
	/**
	 * 
	 * @param drillParams
	 * @return
	 * @throws IOException 
	 */
	public void verifyPrintDrillParam(ArrayList<String> drillParams) throws IOException {
		boolean strFound = false;
		String param = null;
		try {
			List<WebElement> elements = driver.findElements(viz.txtPrintDrillDown());
			for (int k = 0; k < drillParams.size(); k++) {
				strFound = false;
				for(int n = 1; n <= elements.size(); n++) {
					param = driver.findElement(By.xpath("//*[@id=\"athena\"]/div/div[3]/span[" + n + "]")).getText();
					if (param.trim().contains(drillParams.get(k))) {
				    	report.success("Matched", "[Print] Drilldown Parameter :: Expected: " + drillParams.get(k) + " :: Actual: " + param.trim());
						strFound = true;
					} 
				}
				if (!strFound) {
			    	report.error("Not Matched", "[Print] Drilldown Parameter :: Expected: " + drillParams.get(k) + " :: Actual: " + param.trim());
				}				
			}
			if (driver.findElement(By.cssSelector("#athena > div > div.page-header.hidden-print > span.pageTitleStyle")).isDisplayed()){
				driver.navigate().back();
			}
		} catch (TimeoutException e) {
			report.error("Message", "TimeoutException occured: " + e.getMessage());
		} catch (NoSuchElementException e) {
			report.error("Message", "NoSuchElementException occured: " + e.getMessage());
		} catch (NullPointerException e) {
			report.error("Message", "[Print] Object not found");
		} 
	}
	
	
	/**
	 * This method compare the filters value of database and UI filters values
	 * @param dbMap
	 * @param map
	 * @return
	 * @throws IOException 
	 * @throws AWTException 
	 * @throws InterruptedException 
	 */
	public void verifySavedFiltersData(Map<String, String> expData, Map<String, String> actualData) throws IOException, InterruptedException, AWTException {
    	report.success("Message", "[Saved Filter] verifying saved filter data.....");
		for (String key: actualData.keySet()){
            if(actualData.get(key).equals(expData.get(key))) {         
            	report.success("Matched", "[Saved Filter] " + key + " :: Expected: " + expData.get(key) + " :: Actual: " + actualData.get(key));
            }
            else {
            	report.error("Not Matched", "[Saved Filter] " + key + " :: Expected: " + expData.get(key) + " :: Actual: " + actualData.get(key));
            }
		} 
	}
	
	
	/**
	 * 
	 * @throws IOException
	 * @throws InterruptedException
	 */
	public boolean quit() throws IOException, InterruptedException{
    	driver.quit();
    	boolean hasQuit = driver.toString().contains("(null)");
    	if (hasQuit) {
			report.success("Action", "[Connectivity] Connection Closed");
        	return true;
    	}
    	return false;
	}	
	

	/**
	 * 
	 * @param filterName
	 * @param filterDescription
	 * @param setDefault
	 * @return
	 * @throws IOException
	 * @throws InterruptedException
	 * @throws AWTException
	 * @throws SQLException
	 */
	public boolean createSavedFilter(String filterName, String filterDescription, boolean setDefault)throws IOException, InterruptedException, AWTException, SQLException{
		try {
			List<WebElement> element;
			func.getElement(filterObj.savedFilterCreateNewViewIcon()).click();
			element = driver.findElements(filterObj.savedFilterCreateNewViewNameText());
			element.get(5).sendKeys(filterName);
			func.getElement(filterObj.savedFilterCreateNewViewDescriptionText()).sendKeys(filterDescription);
			if (setDefault) func.getElement(filterObj.savedFilterCreateNewViewSetDefaultCheck()).click();
			func.getElement(filterObj.savedFilterCreateNewViewCreateButton()).click();
			Thread.sleep(1000);
			if (wait.waitUntilObjectLoad(filterObj.savedFilterPanelDropDown())) {
				String viewName = func.getElement(filterObj.savedFilterPanelDropDown()).getText();
				if((!setDefault && viewName.equals(filterName)) || (setDefault && viewName.equals(filterName + " (Default)"))) {
					report.success("Action", "[Saved Filter] Filter name (" + filterName + ") was successfully created");
					return true;
				}	
			}			
		}
		catch (TimeoutException e) {
			report.error("Message", "TimeoutException occured: " + e.getMessage());
		} catch (NoSuchElementException e) {
			report.error("Message", "NoSuchElementException occured: " + e.getMessage());
		} catch (NullPointerException e) {
			report.error("Message", "Object not found");
		} 
		return false;
	}
	
	
	/**
	 * 
	 * @param filterName
	 * @param filterDescription
	 * @param setDefault
	 * @return
	 * @throws IOException
	 * @throws InterruptedException
	 */
	public boolean editSavedFilter(String filterName, String filterDescription, boolean setDefault) throws IOException, InterruptedException {
		try {
			if (wait.waitUntilPageLoad()) {
				List<WebElement> element;
				func.getElement(filterObj.savedFilterEditViewIcon()).click();
				element = driver.findElements(filterObj.savedFilterEditViewNameText());
				element.get(6).clear();
				element.get(6).sendKeys(filterName);
				func.getElement(filterObj.savedFilterEditViewDescriptionText()).clear();
				func.getElement(filterObj.savedFilterEditViewDescriptionText()).sendKeys(filterDescription);
				func.getElement(filterObj.savedFilterEditViewSetDefaultCheck()).click();
				func.getElement(filterObj.savedFilterEditViewUpdateButton()).click();
				Thread.sleep(1000);
				if (wait.waitUntilObjectLoad(filterObj.savedFilterPanelDropDown())) {
					List<WebElement> elements=driver.findElements(filterObj.savedFilterPanelList());
					for(int i=0;i<elements.size();i++) {	
						if(elements.get(i).getAttribute("innerText").trim().equals(filterName)) {
							report.success("Action", "[Saved Filter] Filter name was edited as (" + filterName + ") successfully");
							return true;
						}
					}	
				}
			}
		}
		catch (TimeoutException e) {
			report.error("Message", "TimeoutException occured: " + e.getMessage());
		} catch (NoSuchElementException e) {
			report.error("Message", "NoSuchElementException occured: " + e.getMessage());
		} catch (NullPointerException e) {
			report.error("Message", "Object not found");
		} 
		return false;
	}	
	
	
	/**
	 * 
	 * @param filterName
	 * @return
	 * @throws IOException
	 * @throws InterruptedException
	 */
	public boolean deleteSavedFilter(String filterName, boolean savedFilterMenuNotExistsFlag) throws IOException, InterruptedException{
		try {
			if (savedFilterMenuNotExistsFlag) {
				func.getElement(filterObj.savedFilterPanelDropDown()).click();
			}
			List<WebElement> elements=driver.findElements(filterObj.savedFilterPanelList());
			for(int i=0;i<elements.size();i++) {		
				if(elements.get(i).getText().equals(filterName)) {
					driver.findElement(By.xpath("//*[@id='Radio_" + i + "']")).click();
					Thread.sleep(2000);
					driver.findElement(filterObj.savedFilterDeleteViewButton()).click();
					driver.findElement(filterObj.savedFilterDeleteViewDeleteButton()).click();
					report.success("Action", "[Saved Filter] Filter name (" + filterName + ") was successfully deleted from the list");
					return true;
				}
			}
		}
		catch (TimeoutException e) {
			report.error("Message", "TimeoutException occured: " + e.getMessage());
		} catch (NoSuchElementException e) {
			report.error("Message", "NoSuchElementException occured: " + e.getMessage());
		} catch (NullPointerException e) {
			report.error("Message", "Object not found");
		} 
		return false;
	}
	
	
	/**
	 * 
	 * @param filterName
	 * @param savedFilterMenuNotExistsFlag
	 * @return
	 * @throws IOException
	 * @throws InterruptedException
	 * @throws ParseException 
	 */
	public boolean exportAllCSVChecks(String vizName) throws IOException, InterruptedException, ParseException{
		Constants.moduleErrCounter = 0;
		if (func.getElement(viz.btnExportAllCSV()).isDisplayed()) {
			func.getElement(viz.btnExportAllCSV()).click();
			if (wait.waitUntilObjectLoad(viz.btnExportAllExport())) {	
				report.success("Action", "[Export All CSV] Export All CSV triggered");
				dataValidation.exportAllCSV(vizName);
				
				String actTitle = driver.findElement(viz.labelExportAllCSVTitle()).getText();
				String expTitle = "Export All CSV";
				if (actTitle.equals(expTitle)){
		        	report.success("Matched", "[Export All CSV] Title :: Expected: " + expTitle + " :: Actual: " + actTitle);
				} else {
		        	report.error("Not Matched", "[Export All CSV] Title :: Expected: " + expTitle + " :: Actual: " + actTitle);
				}
				
				List<WebElement> elements = driver.findElements(viz.labelExportAllCSVTotalPages());
				String[] arr = elements.get(0).getAttribute("innerText").split(" ");
				if (arr.length>1) {
					String pageCount = arr[1];
					List<WebElement> pageAfter = driver.findElements(viz.btnExportAllCSVPageAfter());
					boolean pageAfterFlag = false;
					for(int j=1;j<Integer.parseInt(pageCount);j++) {
						pageAfter.get(0).click();
						pageAfterFlag = true;
						Thread.sleep(250);
					}
					if (pageAfterFlag) {
						report.success("Action", "[Export All CSV] Page after control is working as expected");
					}
					
					List<WebElement> pagePrev = driver.findElements(viz.btnExportAllCSVPagePrev());
					boolean pagePrevFlag = false;
					for(int j=Integer.parseInt(pageCount);j>1;j--) {
						pagePrev.get(0).click();
						pagePrevFlag = true;
						Thread.sleep(250);
					}
					if (pagePrevFlag) {
						report.success("Action", "[Export All CSV] Page prev control is working as expected");
					}
				}
				else {
					report.error("Action", "[Export All CSV] Total pages in the dialog box looks empty or null");
				}

				if (func.getElement(viz.btnExportAllClose()).isDisplayed()) {
					func.getElement(viz.btnExportAllClose()).click();
				}	
			}
		}
		if (getBooleanConfigData("executeRegression")) report.updateModuleReportExportAllCSVSteps();
		return true;
	}
	
}
