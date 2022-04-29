package common;

import java.io.IOException;
import java.util.NoSuchElementException;

import org.openqa.selenium.By;
import org.openqa.selenium.StaleElementReferenceException;
import org.openqa.selenium.TimeoutException;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebDriverException;
import org.openqa.selenium.support.ui.ExpectedConditions;
import org.openqa.selenium.support.ui.WebDriverWait;

import pages.VizPage;

public class Sync {

	public WebDriver driver;
	WebDriverWait wait;
	VizPage viz;
	Report report;
	int explicitWait;
	
	public Sync(WebDriver driver) throws IOException {
		this.driver = driver;	
		this.viz = new VizPage(driver);
		this.report = new Report();
		this.explicitWait = Base.getNumericConfigData("wait");
	}

	
	/**
	 * 
	 * @throws IOException
	 */
	public boolean waitUntilPageLoad() throws IOException {
		wait = new WebDriverWait(driver, explicitWait);		
		for (int i = 0; i < 2; i++) {			
			try {
				wait.until(ExpectedConditions.visibilityOfElementLocated(viz.iframeChart()));
				driver.switchTo().frame(driver.findElement(viz.iframeChart()));
				wait.until(ExpectedConditions.visibilityOfElementLocated(viz.canvas()));
				wait.until(ExpectedConditions.invisibilityOfElementLocated(viz.spinner()));
				driver.switchTo().defaultContent();
				wait.until(ExpectedConditions.visibilityOfElementLocated(viz.iframeTable()));
				driver.switchTo().frame(driver.findElement(viz.iframeTable()));
				wait.until(ExpectedConditions.visibilityOfElementLocated(viz.canvas()));
				wait.until(ExpectedConditions.invisibilityOfElementLocated(viz.spinner()));
				driver.switchTo().defaultContent();	
				return true;
			} catch (TimeoutException e) {
				if (i == 0) {
					if ((e.getMessage().contains("chart")) && (e.getMessage().contains("iframe")))
						report.warning("Message", "Chart is not loading for (" + (explicitWait * (i+1)) + ") seconds. (" + (i+1) + ") more try..");
					if ((e.getMessage().contains("table")) && (e.getMessage().contains("iframe")))
						report.warning("Message", "Table is not loading for (" + (explicitWait * (i+1)) + ") seconds. (" + (i+1) + ") more try..");
				} 
				else {
					if ((e.getMessage().contains("chart")) && (e.getMessage().contains("iframe")))
						report.error("Message", "Chart is not loading for (" + (explicitWait * (i+1)) + ") seconds.");
					if ((e.getMessage().contains("table")) && (e.getMessage().contains("iframe")))
						report.error("Message", "Table is not loading for (" + (explicitWait * (i+1)) + ") seconds.");
				}					
			} catch (NoSuchElementException e) {
				if (i == 0) 
					report.warning("Message", "NoSuchElementException occured. (" + (i+1) + ") more try..");
				else
					report.error("Message", "NoSuchElementException occured.");					
			} catch (StaleElementReferenceException e) {
				if (i == 0) 
					report.warning("Message", "StaleElementReferenceException occurred. (" + (i+1) + ") more try..");
				else
					report.error("Message", "StaleElementReferenceException occurred.");
			} catch (WebDriverException e) {
				if (i == 0) 
					report.warning("Message", "WebDriverException occurred. (" + (i+1) + ") more try..");
				else
					report.error("Message", "WebDriverException occurred.");
			}
		}		
		driver.switchTo().defaultContent();
		return false;	
	}

	
	/**
	 * 
	 * @throws IOException
	 */
	public boolean waitUntilChartLoad() throws IOException {
		wait = new WebDriverWait(driver, explicitWait);		
		for (int i = 0; i < 2; i++) {
			try {			
				wait.until(ExpectedConditions.visibilityOfElementLocated(viz.iframeChart()));
				driver.switchTo().frame(driver.findElement(viz.iframeChart()));
				wait.until(ExpectedConditions.visibilityOfElementLocated(viz.canvas()));
				wait.until(ExpectedConditions.invisibilityOfElementLocated(viz.spinner()));
				driver.switchTo().defaultContent();
				return true;
			} catch (TimeoutException e) {
				if (i == 0) {
					if ((e.getMessage().contains("chart")) && (e.getMessage().contains("iframe")))
						report.warning("Message", "Chart is not loading for (" + (explicitWait * (i+1)) + ") seconds. (" + (i+1) + ") more try..");
				}
				else {
					if ((e.getMessage().contains("chart")) && (e.getMessage().contains("iframe")))
						report.error("Message", "Chart is not loading for (" + (explicitWait * (i+1)) + ") seconds.");					
				}
			} catch (NoSuchElementException e) {
				if (i == 0) 
					report.warning("Message", "NoSuchElementException occured. (" + (i+1) + ") more try..");
				else
					report.error("Message", "NoSuchElementException occured.");
			} catch (StaleElementReferenceException e) {
				if (i == 0) 
					report.warning("Message", "StaleElementReferenceException occurred. (" + (i+1) + ") more try..");
				else
					report.error("Message", "StaleElementReferenceException occurred.");
			} catch (WebDriverException e) {
				if (i == 0) 
					report.warning("Message", "WebDriverException occurred. (" + (i+1) + ") more try..");
				else
					report.error("Message", "WebDriverException occurred.");
			}
		}
		driver.switchTo().defaultContent();
		return false;			
	}
	
	
	/**
	 * 
	 * @throws IOException
	 */
	public boolean waitUntilTableLoad() throws IOException {
		wait = new WebDriverWait(driver, explicitWait);		
		for (int i = 0; i < 2; i++) {
			try{
				wait.until(ExpectedConditions.visibilityOfElementLocated(viz.iframeTable()));
				driver.switchTo().frame(driver.findElement(viz.iframeTable()));
				wait.until(ExpectedConditions.visibilityOfElementLocated(viz.canvas()));
				wait.until(ExpectedConditions.invisibilityOfElementLocated(viz.spinner()));
				driver.switchTo().defaultContent();
				return true;
			} catch (TimeoutException e) {
				if (i == 0) {
					if ((e.getMessage().contains("table")) && (e.getMessage().contains("iframe")))
						report.warning("Message", "Table is not loading for (" + (explicitWait * (i+1)) + ") seconds. (" + (i+1) + ") more try..");
				}
				else {
					if ((e.getMessage().contains("table")) && (e.getMessage().contains("iframe")))
						report.error("Message", "Table is not loading for (" + (explicitWait * (i+1)) + ") seconds.");
				}
			} catch (NoSuchElementException e) {
				if (i == 0) 
					report.warning("Message", "NoSuchElementException occured. (" + (i+1) + ") more try..");
				else
					report.error("Message", "NoSuchElementException occured.");
			} catch (StaleElementReferenceException e) {
				if (i == 0) 
					report.warning("Message", "StaleElementReferenceException occurred. (" + (i+1) + ") more try..");
				else
					report.error("Message", "StaleElementReferenceException occurred.");
			} catch (WebDriverException e) {
				if (i == 0) 
					report.warning("Message", "WebDriverException occurred. (" + (i+1) + ") more try..");
				else
					report.error("Message", "WebDriverException occurred.");
			}
		}
		driver.switchTo().defaultContent();
		return false;			
	}	
	
	
	/**
	 * 
	 * @param obj
	 * @throws IOException
	 * @throws InterruptedException
	 */
	public boolean waitUntilObjectLoad(By obj) throws IOException, InterruptedException {
		wait = new WebDriverWait(driver, explicitWait);		
		for (int i = 0; i < 2; i++) {
			try {
				wait.until(ExpectedConditions.visibilityOfElementLocated(obj));
				return true;				
			} catch (StaleElementReferenceException e) {
				if (i == 0) 
					report.warning("Message", "StaleElementReferenceException occurred. (" + (i+1) + ") more try..");
				else
					report.error("Message", "StaleElementReferenceException occurred.");
			} catch (WebDriverException e) {
				if (i == 0) 
					report.warning("Message", "WebDriverException occurred. (" + (i+1) + ") more try..");
				else
					report.error("Message", "WebDriverException occurred.");
			}
		}
		return false;			
	}
	
	
	/**
	 * 
	 * @param obj
	 * @throws IOException
	 * @throws InterruptedException
	 */
	public boolean waitUntilDashboardLoad(By obj) throws IOException, InterruptedException {
		wait = new WebDriverWait(driver, explicitWait);		
		for (int i = 0; i < 3; i++) {
			try {
				wait.until(ExpectedConditions.visibilityOfElementLocated(obj));
				return true;
			} catch (Exception e) {
				if (i < 2) {
					report.warning("Message", "Dashboard is not loading for (" + explicitWait + ") seconds. Refreshing page (" + (i + 1) + ") time[s]");
					driver.navigate().refresh();
				} 
			}
		}
		return false;		
	}

}
