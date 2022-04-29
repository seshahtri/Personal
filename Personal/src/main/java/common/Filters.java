package common;

import java.awt.AWTException;
import java.awt.Robot;
import java.awt.event.KeyEvent;
import java.io.IOException;
import java.sql.SQLException;
import java.text.ParseException;
import java.util.ArrayList;
import java.util.List;
import java.util.NoSuchElementException;

import org.openqa.selenium.By;
import org.openqa.selenium.TimeoutException;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;

import pages.FiltersPage;
import config.Constants;

public class Filters extends Base{
	
	public WebDriver driver;
	ArrayList<String> data = new ArrayList<String>();
	Common func;
	Sync wait;
	FiltersPage filterObj;
	Report report;
	Database db;
	Modules test;

	public Filters(WebDriver driver) throws IOException {
		this.driver = driver;	
		this.func = new Common(driver);
		this.wait = new Sync(driver);
		this.filterObj = new FiltersPage(driver);
		this.test = new Modules(driver);
    	this.report = new Report();
    	this.db = new Database();
	}	
	
	
	/**
	 * 
	 * @throws IOException
	 * @throws InterruptedException
	 * @throws SQLException 
	 * @throws AWTException 
	 * @throws ParseException 
	 */
	public void setDefaultFilters() throws IOException, InterruptedException, SQLException, AWTException, ParseException {
		Constants.moduleErrCounter = 0;
		if (getFilterPanel()) {		
			deleteIfDefaultSavedFilterExists();
			report.success("Message", "[Default Filters] Setting default filters for (" + getStringConfigData("client") + ")........");
			setDateFilter(getStringFilterData("DEFAULT-DateRange"), getStringFilterData("DEFAULT-StartDate"), getStringFilterData("DEFAULT-EndDate"));
			setCurrencyFilter(getStringFilterData("DEFAULT-Currency"));
			setInvoiceOptionsFilter(getStringFilterData("DEFAULT-InvoiceStatus"));
			setReviewStatusFilter(getStringFilterData("DEFAULT-ReviewStatus"));
		}
		if (Base.getBooleanConfigData("executeRegression")) report.updateModuleReportSetDefaultFilterSteps();
	}


	/**
	 * 
	 * @throws IOException
	 * @throws InterruptedException
	 * @throws SQLException 
	 * @throws AWTException 
	 */
	public boolean setCustomFilters() throws IOException, InterruptedException, SQLException, AWTException {
		if (getFilterPanel()) {		
			deleteIfDefaultSavedFilterExists();
			switch(getStringConfigData("client")) {
				case "C00348":
					report.success("Message", "[Custom Filters] Setting custom filters for (" + getStringConfigData("client") + ")........");
					setDateFilter(getStringFilterData("C00348-DateRange"), getStringFilterData("C00348-StartDate"), getStringFilterData("C00348-EndDate"));
					setCurrencyFilter(getStringFilterData("C00348-Currency"));
					setInvoiceOptionsFilter(getStringFilterData("C00348-InvoiceStatus"));
					setInvoiceDateFieldFilter(getStringFilterData("C00348-InvoiceDate"));
					setClientLevelFilter(getStringFilterData("C00348-ClientLevel"));
					setGBLocationFilter(getStringFilterData("C00348-GBLocation"));					
					setMatterStatusFilter(getStringFilterData("C00348-MatterStatus"));					
					setMatterNameFilter(getStringFilterData("C00348-MatterName"));					
					setMatterOwnerFilter(getStringFilterData("C00348-MatterOwner"));					
					setVendorNameFilter(getStringFilterData("C00348-VendorName"));					
					setVendorTypeFilter(getStringFilterData("C00348-VendorType"));					
					setDFCountryFilter(getStringFilterData("C00348-DFCountry"));					
					setDFCoverageGroupFilter(getStringFilterData("C00348-DFCoverageGroup"));					
					setDFCoverageTypeFilter(getStringFilterData("C00348-DFCoverageType"));					
					setDFBenefitStateFilter(getStringFilterData("C00348-DFBenefitState"));					
					setDFAccidentStateFilter(getStringFilterData("C00348-DFAccidentState"));					
					setDFStatusCodeFilter(getStringFilterData("C00348-DFStatusCode"));					
					setDFClaimNumberFilter(getStringFilterData("C00348-DFClaimNumber"));					
					setDFGBBranchNameFilter(getStringFilterData("C00348-DFGBBranchName"));					
					setDFGBBranchNumberFilter(getStringFilterData("C00348-DFGBBranchNumber"));					
					return true;
					
				case "DEV044":
					report.success("Message", "[Custom Filters] Setting custom filters for (" + getStringConfigData("client") + ")........");
					setDateFilter(getStringFilterData("DEV044-DateRange"), getStringFilterData("DEV044-StartDate"), getStringFilterData("DEV044-EndDate"));
					setCurrencyFilter(getStringFilterData("DEV044-Currency"));
					setInvoiceOptionsFilter(getStringFilterData("DEV044-InvoiceStatus"));
					setInvoiceDateFieldFilter(getStringFilterData("DEV044-InvoiceDate"));
					setMatterNameFilter(getStringFilterData("DEV044-MatterName"));
					setMatterNumberFilter(getStringFilterData("DEV044-MatterNumber"));
					setMatterStatusFilter(getStringFilterData("DEV044-MatterStatus"));
					setMatterOwnerFilter(getStringFilterData("DEV044-MatterOwner"));
					setVendorNameFilter(getStringFilterData("DEV044-VendorName"));					
					setVendorTypeFilter(getStringFilterData("DEV044-VendorType"));
					setPracticeAreaFilter(getStringFilterData("DEV044-PracticeArea"));
					setBusinessUnitFilter(getStringFilterData("DEV044-BusinessUnit"));
					return true;				
			}
		}
		return false;										
	}	
	

	/**
	 * 
	 * @param vizName
	 * @throws IOException
	 * @throws InterruptedException
	 */
	public void deleteIfDefaultSavedFilterExists() throws IOException, InterruptedException {
		func.getElement(filterObj.savedFilterPanelDropDown()).click();
		List<WebElement> dropDownElements=driver.findElements(filterObj.savedFilterPanelList());
		for(int i=0;i<dropDownElements.size();i++) {		
			if(dropDownElements.get(i).getText().contains("Default")) {
				report.success("Message", "[Saved Filter] Default saved filter (" + dropDownElements.get(i).getText() + ") exists");
				test.deleteSavedFilter(dropDownElements.get(i).getText(), false);
			}
		}
		func.getElement(filterObj.savedFilterPanelDropDown()).click();
	}
	
	
	/**
	 * 
	 * @param vizName
	 * @throws IOException
	 * @throws InterruptedException
	 */
	public void deleteIfCustomSavedFilterExists(ArrayList<String> savedFilters) throws IOException, InterruptedException {
		if (getFilterPanel()) {
			boolean savedFilterMenuNotExistsFlag = true; 
			int counter = 0;
			for(int a=0;a<savedFilters.size();a++) {
				if (savedFilterMenuNotExistsFlag)	{
					func.getElement(filterObj.savedFilterPanelDropDown()).click();
				}
				List<WebElement> dropDownElements=driver.findElements(filterObj.savedFilterPanelList());
				for(int i=0;i<dropDownElements.size();i++) {		
					String savedView = dropDownElements.get(i).getAttribute("innerText").trim();					
					if(savedView.equals(savedFilters.get(a)) || savedView.equals(savedFilters.get(a) + " (Default)")) {
						report.success("Message", "[Prerequisite - Saved filters] (" + savedView + ") already exists in the list and needs a deletion");
						test.deleteSavedFilter(savedView, false);
						savedFilterMenuNotExistsFlag = true;
						counter++;
						break;
					} else {
						savedFilterMenuNotExistsFlag = false;
					}
				}
			}
			if (counter == 0) {
				for(int a=0;a<savedFilters.size();a++) {
					report.success("Message", "[Prerequisite - Saved filters] (" + savedFilters.get(a) + ") not exists in the list");	
				}
			}
		}
	}
	
	
	/**
	 * 
	 * @return
	 * @throws IOException
	 * @throws InterruptedException
	 */
	public boolean getFilterPanel() throws IOException, InterruptedException {			
		try {		
			WebElement element = driver.findElement(By.cssSelector("div.globalFilterPane"));
			if ((Integer.parseInt((element.getCssValue("width")).substring(0, element.getCssValue("width").indexOf("p")))) < 5) {
				func.getElement(filterObj.filterExpansionButton()).click();
				return true;				
			} 
		} catch (TimeoutException e) {
			report.error("Message", "TimeoutException occured: " + e.getMessage());
		} catch (NoSuchElementException e) {
			report.error("Message", "NoSuchElementException occured: " + e.getMessage());
		} catch (NullPointerException e) {
			report.error("Message", "[Filter] Object not found");
		} 
		report.error("Message", "Filter Panel not Expanded");
		return false;
	}	

	
	/**
	 * 
	 * @param data
	 * @throws IOException
	 * @throws InterruptedException
	 */
	public void setDateFilter(String dateRange, String startDate, String endDate) throws IOException, InterruptedException {
//		if (!dateRange.equals("-1")) {
//			if (func.getElement(By.xpath("//span[text()='Date Range']")).isDisplayed()) {
//				WebElement element = driver.findElement(By.xpath("//span[text()='Date Range']/span"));
//				if (element.getAttribute("class").contains("right")) {
//					func.getElement(By.xpath("//span[text()='Date Range']/span")).click();
//				}
//				if (func.getElement(By.xpath("//input[@type='radio'] [@value='" + dateRange + "']")).isDisplayed()) {
//					func.getElement(By.xpath("//input[@type='radio'] [@value='" + dateRange + "']")).click();	
//			    	report.success("Action", "[Filter] Date Range: " + dateRange);
//				}
//				if (dateRange.equals("Other")) {
//					func.getElement(By.xpath("//input[@name='dateStart']")).sendKeys(startDate);
//			    	report.success("Action", "[Filter] Start Date: " + startDate);
//					func.getElement(By.xpath("//input[@name='dateEnd']")).sendKeys(endDate);
//			    	report.success("Action", "[Filter] End Date: " + endDate);
//				}
//			} else {
//		    	report.error("Message", "[Filter] Date Range filter not exists in the filter panel");
//			}
//		}
	}
	
	
	
	/**
	 * 
	 * @param data
	 * @throws IOException
	 * @throws InterruptedException
	 */
	public void setCurrencyFilter(String currency) throws IOException, InterruptedException {
		if (!currency.equals("-1")) {
			if (func.getElement(By.xpath("//span[text()='Currency']")).isDisplayed()) {
				WebElement element = driver.findElement(By.xpath("//span[text()='Currency']/span"));
				if (element.getAttribute("class").contains("right")) func.getElement(By.xpath("//span[text()='Currency']/span")).click();
				if (func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "Currency button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).isDisplayed()) {
					func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "Currency button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).click();		
					if (func.getElement(By.xpath("//label[text()='" + currency + "']")).isDisplayed()) {
						func.getElement(By.xpath("//label[text()='" + currency + "']")).click();	
				    	report.success("Action", "[Filter] Currency: " + currency);
					}
				}
			} else {
		    	report.error("Message", "[Filter] Currency filter not exists in the filter panel");
			}
		}
	}
	
	
	/**
	 * 
	 * @param data
	 * @throws IOException
	 * @throws InterruptedException
	 */
	public void setReviewStatusFilter(String ReviewStatus) throws IOException, InterruptedException {
		if (!ReviewStatus.equals("-1")) {
			if (func.getElement(By.xpath("//span[text()='Review Status']")).isDisplayed()) {
				WebElement element = driver.findElement(By.xpath("//span[text()='Review Status']/span"));
				if (element.getAttribute("class").contains("right")) func.getElement(By.xpath("//span[text()='Review Status']/span")).click();
				if (func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "ReviewStatus button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).isDisplayed()) {			
					func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "ReviewStatus button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).click();
					
//					String[] defaultReviewOptions = {"Complete", "In LBA Review"};
//					for (int i=0; i<defaultReviewOptions.length; i++) {
//						if (func.getElement(By.xpath("//input[@name='" +  getStringConfigData("client") + "ReviewStatus' and @value='" + defaultReviewOptions[i].trim() + "']")).isDisplayed()) {
//							func.getElement(By.xpath("//input[@name='" +  getStringConfigData("client") + "ReviewStatus' and @value='" + defaultReviewOptions[i].trim() + "']")).click();	
//						}					
//					}
					String[] temp = ReviewStatus.split(";");
					for (int i=0; i<temp.length;i++) {				
						if (func.getElement(By.xpath("//input[@name='" +  getStringConfigData("client") + "ReviewStatus' and @value='" + temp[i].trim() + "']")).isDisplayed()) {
							func.getElement(By.xpath("//input[@name='" +  getStringConfigData("client") + "ReviewStatus' and @value='" + temp[i].trim() + "']")).click();	
					    	report.success("Action", "[Filter] Review Status: " + temp[i].trim());
						}		
					}
					func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "ReviewStatus button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).click();
				}
			} else {
		    	report.error("Message", "[Filter] Review Status filter not exists in the filter panel");
			}
		}
	}

	
	/**
	 * 
	 * @param data
	 * @throws IOException
	 * @throws InterruptedException
	 */
	public void setInvoiceOptionsFilter(String invoiceStatus) throws IOException, InterruptedException {
		if (!invoiceStatus.equals("-1")) {
			if (func.getElement(By.xpath("//span[text()='Invoice Options']")).isDisplayed()) {
				WebElement element = driver.findElement(By.xpath("//span[text()='Invoice Options']/span"));
				if (element.getAttribute("class").contains("right")) func.getElement(By.xpath("//span[text()='Invoice Options']/span")).click();
				if (func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "InvoiceStatus button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).isDisplayed()) {			
					String[] defaultInvoiceOptions = {"Paid", "Processed"};
					func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "InvoiceStatus button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).click();
					for (int i=0; i<defaultInvoiceOptions.length; i++) {
						if (func.getElement(By.xpath("//input[@name='" +  getStringConfigData("client") + "InvoiceStatus' and @value='" + defaultInvoiceOptions[i].trim() + "']")).isDisplayed()) {
							func.getElement(By.xpath("//input[@name='" +  getStringConfigData("client") + "InvoiceStatus' and @value='" + defaultInvoiceOptions[i].trim() + "']")).click();	
						}					
					}
					String[] temp = invoiceStatus.split(";");
					for (int i=0; i<temp.length;i++) {				
						if (func.getElement(By.xpath("//input[@name='" +  getStringConfigData("client") + "InvoiceStatus' and @value='" + temp[i].trim() + "']")).isDisplayed()) {
							func.getElement(By.xpath("//input[@name='" +  getStringConfigData("client") + "InvoiceStatus' and @value='" + temp[i].trim() + "']")).click();	
					    	report.success("Action", "[Filter] Invoice Option: " + temp[i].trim());
						}		
					}
					func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "InvoiceStatus button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).click();
				}
			} else {
		    	report.error("Message", "[Filter] Invoice Options filter not exists in the filter panel");
			}
		}
	}
	

	/**
	 * 
	 * @param data
	 * @throws IOException
	 * @throws InterruptedException
	 */
	public void setInvoiceDateFieldFilter(String invoiceDate) throws IOException, InterruptedException {	
		invoiceDate = "Invoice Date";
		String locator = null;
		List<WebElement> element = driver.findElements(By.xpath("//span[text()='More ']/span"));
		if (element.get(3).getAttribute("class").contains("right")) element.get(3).click();	
		if (Base.getStringConfigData("client").equals("C00348")) locator = "_InvoiceDateField button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left";
		if (Base.getStringConfigData("client").equals("DEV044")) locator = "InvoiceDateField button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left";
		if (func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + locator)).isDisplayed()) {
			func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + locator)).click();
			if (func.getElement(By.xpath("//label[contains(text(),'" + invoiceDate.trim() + "')]")).isDisplayed()) {
				func.getElement(By.xpath("//label[contains(text(),'" + invoiceDate.trim() + "')]")).click();	
		    	report.success("Message", "[Filter] InvoiceDate: " + invoiceDate.trim());
			}			
			func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + locator)).click();
		}
	}

	
	/**
	 * 
	 * @param data
	 * @throws IOException
	 * @throws InterruptedException
	 */
	public void setPracticeAreaFilter(String PracticeArea) throws IOException, InterruptedException {
		if (!PracticeArea.equals("-1")) {		
			if (func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "PracticeArea button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).isDisplayed()) {
				func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "PracticeArea button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).click();
				String[] temp = PracticeArea.split(";");
				for (int i=0; i<temp.length;i++) {
					if (func.getElement(By.xpath("//a[contains(text(),'" + temp[i].trim() + "')]")).isDisplayed()) {
						func.getElement(By.xpath("//a[contains(text(),'" + temp[i].trim() + "')]")).click();	
				    	report.success("Action", "[Filter] Practice Area: " + temp[i].trim());
					}					
				}	
				func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "PracticeArea button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).click();
			} else {
		    	report.error("Message", "[Filter] Practice Area filter not exists in the filter panel");
			}
		} 
	}
	

	/**
	 * 
	 * @param data
	 * @throws IOException
	 * @throws InterruptedException
	 */
	public void setClientLevelFilter(String clientLevel) throws IOException, InterruptedException {
		if (!clientLevel.equals("-1")) {		
			if (func.getElement(By.xpath("//span[text()='Client Level']")).isDisplayed()) {
				WebElement element = driver.findElement(By.xpath("//span[text()='Client Level']/span"));
				if (element.getAttribute("class").contains("right")) func.getElement(By.xpath("//span[text()='Client Level']/span")).click();			
				if (func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "PracticeArea button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).isDisplayed()) {
					func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "PracticeArea button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).click();
					String[] temp = clientLevel.split(";");
					for (int i=0; i<temp.length;i++) {
						if (func.getElement(By.xpath("//a[contains(text(),'" + temp[i].trim() + "')]")).isDisplayed()) {
							func.getElement(By.xpath("//a[contains(text(),'" + temp[i].trim() + "')]")).click();	
					    	report.success("Action", "[Filter] Client Level: " + temp[i].trim());
						}					
					}	
					func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "PracticeArea button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).click();
				}
			} else {
		    	report.error("Message", "[Filter] Client Level filter not exists in the filter panel");
			}
		}
	}

	
	
	/**
	 * 
	 * @param data
	 * @throws IOException
	 * @throws InterruptedException
	 */
	public void setGBLocationFilter(String GBLocation) throws IOException, InterruptedException {		
		if (!GBLocation.equals("-1")) {
			List<WebElement> element = driver.findElements(By.xpath("//span[text()='More ']/span"));
			if (element.get(0).getAttribute("class").contains("right")) element.get(0).click();		
			if (func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "BusinessUnit button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).isDisplayed()) {
				func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "BusinessUnit button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).click();
				String[] temp = GBLocation.split(";");
				for (int i=0; i<temp.length;i++) {
					if (func.getElement(By.xpath("//a[contains(text(),'" + temp[i].trim() + "')]")).isDisplayed()) {
						func.getElement(By.xpath("//a[contains(text(),'" + temp[i].trim() + "')]")).click();	
				    	report.success("Action", "[Filter] GB Location: " + temp[i].trim());
					}					
				}	
				func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "BusinessUnit button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).click();
			}
		}
	}
	
	
	/**
	 * 
	 * @param data
	 * @throws IOException
	 * @throws InterruptedException
	 */
	public void setBusinessUnitFilter(String BusinessUnit) throws IOException, InterruptedException {		
		if (!BusinessUnit.equals("-1")) {
			List<WebElement> element = driver.findElements(By.xpath("//span[text()='More ']/span"));
			if (element.get(2).getAttribute("class").contains("right")) element.get(2).click();		
			if (func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "BusinessUnit button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).isDisplayed()) {
				func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "BusinessUnit button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).click();
				String[] temp = BusinessUnit.split(";");
				for (int i=0; i<temp.length;i++) {
					if (func.getElement(By.xpath("//a[contains(text(),'" + temp[i].trim() + "')]")).isDisplayed()) {
						func.getElement(By.xpath("//a[contains(text(),'" + temp[i].trim() + "')]")).click();	
				    	report.success("Action", "[Filter] Business Unit: " + temp[i].trim());
					}					
				}	
				func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "BusinessUnit button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).click();
			}
		}
	}
	
	
	/**
	 * 
	 * @param data
	 * @throws IOException
	 * @throws InterruptedException
	 */
	public void setMatterStatusFilter(String matterStatus) throws IOException, InterruptedException {
		if (!matterStatus.equals("-1")) {
			if (func.getElement(By.xpath("//span[text()='Matter']")).isDisplayed()) {
				WebElement element = driver.findElement(By.xpath("//span[text()='Matter']/span"));
				if (element.getAttribute("class").contains("right")) func.getElement(By.xpath("//span[text()='Matter']/span")).click();			
				if (func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "_MatterStatus button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).isDisplayed()) {
					String[] temp = matterStatus.split(";");
					func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "_MatterStatus button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).click();
					for (int i=0; i<temp.length;i++) {
						if (func.getElement(By.xpath("//input[@name='" +  getStringConfigData("client") + "_MatterStatus' and @value='" + temp[i].trim() + "']")).isDisplayed()) {
							func.getElement(By.xpath("//input[@name='" +  getStringConfigData("client") + "_MatterStatus' and @value='" + temp[i].trim() + "']")).click();	
					    	report.success("Action", "[Filter] Matter Status: " + temp[i].trim());
						}		
					}
					func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "_MatterStatus button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).click();
				}
			} else {
		    	report.error("Message", "[Filter] Matter Status filter not exists in the filter panel");
			}
		}
	}
	

	/**
	 * 
	 * @param data
	 * @throws IOException
	 * @throws InterruptedException
	 * @throws AWTException 
	 */
	public void setMatterNameFilter(String matterName) throws IOException, InterruptedException, AWTException {	
		if (!matterName.equals("-1")) {
			List<WebElement> element = driver.findElements(By.xpath("//span[text()='More ']/span"));
			if (element.get(1).getAttribute("class").contains("right")) element.get(1).click();		
			if (func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "Matter button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).isDisplayed()) {
				String[] temp = matterName.split(";");
				for (int i=0; i<temp.length;i++) {
					func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "Matter button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).click();
					if (func.getElement(By.xpath("//label[contains(text(),'" + temp[i].trim() + "')]")).isDisplayed()) {
						func.getElement(By.xpath("//label[contains(text(),'" + temp[i].trim() + "')]")).click();	
				    	report.success("Message", "[Filter] Matter Name: " + temp[i].trim());
					} else {
						if (func.getElement(By.xpath("//input[@placeholder='Search for Matter Name']")).isDisplayed()) {
							func.getElement(By.xpath("//input[@placeholder='Search for Matter Name']")).sendKeys(temp[i].trim());;	
					    	report.success("Action", "[Filter] Matter Name: " + temp[i].trim());

					    	Robot robot = new Robot();
					    	robot.delay(1000);
							robot.keyPress(KeyEvent.VK_ENTER);
						    robot.keyRelease(KeyEvent.VK_ENTER);
						    robot.delay(500);
						}						
					
						if (func.getElement(By.xpath("//label[contains(text(),'" + temp[i].trim() + "')]")).isDisplayed()) {
							func.getElement(By.xpath("//label[contains(text(),'" + temp[i].trim() + "')]")).click();	
					    	report.success("Action", "[Filter] Matter Name: " + temp[i].trim());
						}						
					}
				}
			}
		}
	}
	

	/**
	 * 
	 * @param data
	 * @throws IOException
	 * @throws InterruptedException
	 * @throws AWTException 
	 */
	public void setMatterNumberFilter(String matterNumber) throws IOException, InterruptedException, AWTException {	
		if (!matterNumber.equals("-1")) {
			List<WebElement> element = driver.findElements(By.xpath("//span[text()='More ']/span"));
			if (element.get(0).getAttribute("class").contains("right")) element.get(0).click();		
			if (func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "MatterNumber button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).isDisplayed()) {
				String[] temp = matterNumber.split(";");
				for (int i=0; i<temp.length;i++) {
					func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "MatterNumber button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).click();
					element = driver.findElements(By.xpath("//label[contains(text(),'" + temp[i].trim() + "')]"));
					if (element.get(1).isDisplayed()) {
						element.get(1).click();
						report.success("Message", "[Filter] Matter Number: " + temp[i].trim());
					} else {
						if (func.getElement(By.xpath("//input[@placeholder='Search for Matter Number']")).isDisplayed()) {
							func.getElement(By.xpath("//input[@placeholder='Search for Matter Number']")).sendKeys(temp[i].trim());;	
					    	report.success("Action", "[Filter] Matter Number: " + temp[i].trim());

					    	Robot robot = new Robot();
					    	robot.delay(1000);
							robot.keyPress(KeyEvent.VK_ENTER);
						    robot.keyRelease(KeyEvent.VK_ENTER);
						    robot.delay(500);
						}						
					
						if (func.getElement(By.xpath("//label[contains(text(),'" + temp[i].trim() + "')]")).isDisplayed()) {
							func.getElement(By.xpath("//label[contains(text(),'" + temp[i].trim() + "')]")).click();	
					    	report.success("Action", "[Filter] Matter Number: " + temp[i].trim());
						}						
					}
				}
			}
		}
	}

	
	/**
	 * 
	 * @param data
	 * @throws IOException
	 * @throws InterruptedException
	 */
	public void setMatterOwnerFilter(String matterOwner) throws IOException, InterruptedException {	
		if (!matterOwner.equals("-1")) {
			List<WebElement> element = driver.findElements(By.xpath("//span[text()='More ']/span"));
			if (element.get(1).getAttribute("class").contains("right")) element.get(1).click();		
			if (func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "MatterOwner button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).isDisplayed()) {
				String[] temp = matterOwner.split(";");
				for (int i=0; i<temp.length;i++) {
					func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "MatterOwner button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).click();
					if (func.getElement(By.xpath("//label[contains(text(),'" + temp[i].trim() + "')]")).isDisplayed()) {
						func.getElement(By.xpath("//label[contains(text(),'" + temp[i].trim() + "')]")).click();	
				    	report.success("Action", "[Filter] Matter Owner: " + temp[i].trim());
					}		
				}
			}
		}
	}

	
	/**
	 * 
	 * @param data
	 * @throws IOException
	 * @throws InterruptedException
	 */
	public void setVendorNameFilter(String vendorName) throws IOException, InterruptedException {
		if (!vendorName.equals("-1")) {
			if (func.getElement(By.xpath("//span[text()='Vendor']")).isDisplayed()) {
				WebElement element = driver.findElement(By.xpath("//span[text()='Vendor']/span"));
				if (element.getAttribute("class").contains("right")) func.getElement(By.xpath("//span[text()='Vendor']/span")).click();			
				if (func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "Vendor button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).isDisplayed()) {
					String[] temp = vendorName.split(";");
					for (int i=0; i<temp.length;i++) {
						func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "Vendor button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).click();
						if (func.getElement(By.xpath("//label[contains(text(),'" + temp[i].trim() + "')]")).isDisplayed()) {
							func.getElement(By.xpath("//label[contains(text(),'" + temp[i].trim() + "')]")).click();	
					    	report.success("Action", "[Filter] Vendor Name: " + temp[i].trim());
						}					
					}	
				}
			} else {
		    	report.error("Message", "[Filter] Vendor Name filter not exists in the filter panel");
			}
		}
	}
	

	/**
	 * 
	 * @param data
	 * @throws IOException
	 * @throws InterruptedException
	 */
	public void setVendorTypeFilter(String vendorType) throws IOException, InterruptedException {		
		if (!vendorType.equals("-1")) {
			List<WebElement> element = driver.findElements(By.xpath("//span[text()='More ']/span"));
			if (element.get(2).getAttribute("class").contains("right")) element.get(2).click();		
			if (func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "VendorType button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).isDisplayed()) {
				String[] temp = vendorType.split(";");
				func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "VendorType button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).click();
				for (int i=0; i<temp.length;i++) {
					if (func.getElement(By.xpath("//input[@name='" +  getStringConfigData("client") + "VendorType' and @value='" + temp[i].trim() + "']")).isDisplayed()) {
						func.getElement(By.xpath("//input[@name='" +  getStringConfigData("client") + "VendorType' and @value='" + temp[i].trim() + "']")).click();	
				    	report.success("Action", "[Filter] Vendor Type: " + temp[i].trim());
					}		
				}
				func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "VendorType button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).click();
			}
		}
	}

	
	/**
	 * 
	 * @param data
	 * @throws IOException
	 * @throws InterruptedException
	 */
	public void setDFCountryFilter(String DFCountry) throws IOException, InterruptedException {
		if (!DFCountry.equals("-1")) {
			if (func.getElement(By.xpath("//span[text()='Dynamic Fields']")).isDisplayed()) {
				WebElement element = driver.findElement(By.xpath("//span[text()='Dynamic Fields']/span"));
				if (element.getAttribute("class").contains("right")) func.getElement(By.xpath("//span[text()='Dynamic Fields']/span")).click();			
				if (func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "_DynamicFields button.dynamicFieldFilterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).isDisplayed()) {
					func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "_DynamicFields button.dynamicFieldFilterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).click();
					if (func.getElement(By.xpath("//a[contains(text(),'Country')]")).isDisplayed()) {
						func.getElement(By.xpath("//a[contains(text(),'Country')]")).click();	
					}					
					func.getElement(By.cssSelector("button.btn.btn-secondary.btn-xs")).click();
					
					if (func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "_DF_1_CountryWhereSuitwasFiled button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).isDisplayed()) {
						String[] temp = DFCountry.split(";");
						func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "_DF_1_CountryWhereSuitwasFiled button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).click();
						for (int i=0; i<temp.length;i++) {
							if (func.getElement(By.xpath("//input[@name='" +  getStringConfigData("client") + "_DF_1_CountryWhereSuitwasFiled' and @value='" + temp[i].trim() + "']")).isDisplayed()) {
								func.getElement(By.xpath("//input[@name='" +  getStringConfigData("client") + "_DF_1_CountryWhereSuitwasFiled' and @value='" + temp[i].trim() + "']")).click();	
						    	report.success("Action", "[Filter] DF Country: " + temp[i].trim());
							}		
						}
						func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "_DF_1_CountryWhereSuitwasFiled button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).click();
					}
				}
			} else {
		    	report.error("Message", "[Filter] DF Country filter not exists in the filter panel");
			}
		}
	}
	
	
	/**
	 * 
	 * @param data
	 * @throws IOException
	 * @throws InterruptedException
	 */
	public void setDFCoverageGroupFilter(String DFCoverageGroup) throws IOException, InterruptedException {
		if (!DFCoverageGroup.equals("-1")) {
			if (func.getElement(By.xpath("//span[text()='Dynamic Fields']")).isDisplayed()) {
				WebElement element = driver.findElement(By.xpath("//span[text()='Dynamic Fields']/span"));
				if (element.getAttribute("class").contains("right")) func.getElement(By.xpath("//span[text()='Dynamic Fields']/span")).click();			
				if (func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "_DynamicFields button.dynamicFieldFilterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).isDisplayed()) {
					func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "_DynamicFields button.dynamicFieldFilterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).click();
					if (func.getElement(By.xpath("//a[contains(text(),'Coverage Group')]")).isDisplayed()) {
						func.getElement(By.xpath("//a[contains(text(),'Coverage Group')]")).click();	
					}					
					func.getElement(By.cssSelector("button.btn.btn-secondary.btn-xs")).click();
					
					if (func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "_DF_2_CoverageGroup button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).isDisplayed()) {
						String[] temp = DFCoverageGroup.split(";");
						func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "_DF_2_CoverageGroup button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).click();
						for (int i=0; i<temp.length;i++) {
							if (func.getElement(By.xpath("//input[@name='" +  getStringConfigData("client") + "_DF_2_CoverageGroup' and @value='" + temp[i].trim() + "']")).isDisplayed()) {
								func.getElement(By.xpath("//input[@name='" +  getStringConfigData("client") + "_DF_2_CoverageGroup' and @value='" + temp[i].trim() + "']")).click();	
						    	report.success("Action", "[Filter] DF Coverage Group: " + temp[i].trim());
							}		
						}
						func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "_DF_2_CoverageGroup button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).click();
					}
				}
			} else {
		    	report.error("Message", "[Filter] DF Coverage Group filter not exists in the filter panel");
			}
		}
	}
	
	
	/**
	 * 
	 * @param data
	 * @throws IOException
	 * @throws InterruptedException
	 */
	public void setDFCoverageTypeFilter(String DFCoverageType) throws IOException, InterruptedException {
		if (!DFCoverageType.equals("-1")) {
			if (func.getElement(By.xpath("//span[text()='Dynamic Fields']")).isDisplayed()) {
				WebElement element = driver.findElement(By.xpath("//span[text()='Dynamic Fields']/span"));
				if (element.getAttribute("class").contains("right")) func.getElement(By.xpath("//span[text()='Dynamic Fields']/span")).click();			
				if (func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "_DynamicFields button.dynamicFieldFilterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).isDisplayed()) {
					func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "_DynamicFields button.dynamicFieldFilterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).click();
					if (func.getElement(By.xpath("//a[contains(text(),'Coverage Type')]")).isDisplayed()) {
						func.getElement(By.xpath("//a[contains(text(),'Coverage Type')]")).click();	
					}					
					func.getElement(By.cssSelector("button.btn.btn-secondary.btn-xs")).click();
					
					if (func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "_DF_3_CoverageType button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).isDisplayed()) {
						String[] temp = DFCoverageType.split(";");
						func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "_DF_3_CoverageType button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).click();
						for (int i=0; i<temp.length;i++) {				
							if (func.getElement(By.xpath("//input[@name='" +  getStringConfigData("client") + "_DF_3_CoverageType' and @value='" + temp[i].trim() + "']")).isDisplayed()) {
								func.getElement(By.xpath("//input[@name='" +  getStringConfigData("client") + "_DF_3_CoverageType' and @value='" + temp[i].trim() + "']")).click();	
						    	report.success("Action", "[Filter] DF Coverage Type: " + temp[i].trim());
							}		
						}
						func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "_DF_3_CoverageType button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).click();
					}
				}
			} else {
		    	report.error("Message", "[Filter] DF Coverage Type filter not exists in the filter panel");
			}
		}
	}	
	
	
	/**
	 * 
	 * @param data
	 * @throws IOException
	 * @throws InterruptedException
	 */
	public void setDFBenefitStateFilter(String DFBenefitState) throws IOException, InterruptedException {
		if (!DFBenefitState.equals("-1")) {
			if (func.getElement(By.xpath("//span[text()='Dynamic Fields']")).isDisplayed()) {
				WebElement element = driver.findElement(By.xpath("//span[text()='Dynamic Fields']/span"));
				if (element.getAttribute("class").contains("right")) func.getElement(By.xpath("//span[text()='Dynamic Fields']/span")).click();			
				if (func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "_DynamicFields button.dynamicFieldFilterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).isDisplayed()) {
					func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "_DynamicFields button.dynamicFieldFilterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).click();
					if (func.getElement(By.xpath("//a[contains(text(),'Benefit State')]")).isDisplayed()) {
						func.getElement(By.xpath("//a[contains(text(),'Benefit State')]")).click();	
					}					
					func.getElement(By.cssSelector("button.btn.btn-secondary.btn-xs")).click();
					
					if (func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "_DF_4_BenefitState button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).isDisplayed()) {
						String[] temp = DFBenefitState.split(";");
						func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "_DF_4_BenefitState button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).click();
						for (int i=0; i<temp.length;i++) {				
							if (func.getElement(By.xpath("//input[@name='" +  getStringConfigData("client") + "_DF_4_BenefitState' and @value='" + temp[i].trim() + "']")).isDisplayed()) {
								func.getElement(By.xpath("//input[@name='" +  getStringConfigData("client") + "_DF_4_BenefitState' and @value='" + temp[i].trim() + "']")).click();	
						    	report.success("Action", "[Filter] DF Benefit State: " + temp[i].trim());
							}		
						}
						func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "_DF_4_BenefitState button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).click();
					}
				}
			} else {
		    	report.error("Message", "[Filter] DF Benefit State filter not exists in the filter panel");
			}
		}
	}
	
	
	/**
	 * 
	 * @param data
	 * @throws IOException
	 * @throws InterruptedException
	 */
	public void setDFAccidentStateFilter(String DFAccidentState) throws IOException, InterruptedException {
		if (!DFAccidentState.equals("-1")) {
			if (func.getElement(By.xpath("//span[text()='Dynamic Fields']")).isDisplayed()) {
				WebElement element = driver.findElement(By.xpath("//span[text()='Dynamic Fields']/span"));
				if (element.getAttribute("class").contains("right")) func.getElement(By.xpath("//span[text()='Dynamic Fields']/span")).click();			
				if (func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "_DynamicFields button.dynamicFieldFilterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).isDisplayed()) {
					func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "_DynamicFields button.dynamicFieldFilterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).click();
					if (func.getElement(By.xpath("//a[contains(text(),'Accident State')]")).isDisplayed()) {
						func.getElement(By.xpath("//a[contains(text(),'Accident State')]")).click();	
					}					
					func.getElement(By.cssSelector("button.btn.btn-secondary.btn-xs")).click();
					
					if (func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "_DF_5_AccidentState button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).isDisplayed()) {
						String[] temp = DFAccidentState.split(";");
						func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "_DF_5_AccidentState button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).click();
						for (int i=0; i<temp.length;i++) {				
							if (func.getElement(By.xpath("//input[@name='" +  getStringConfigData("client") + "_DF_5_AccidentState' and @value='" + temp[i].trim() + "']")).isDisplayed()) {
								func.getElement(By.xpath("//input[@name='" +  getStringConfigData("client") + "_DF_5_AccidentState' and @value='" + temp[i].trim() + "']")).click();	
						    	report.success("Action", "[Filter] DF Accident State: " + temp[i].trim());
							}		
						}
						func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "_DF_5_AccidentState button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).click();
					}
				}
			} else {
		    	report.error("Message", "[Filter] DF Accident State filter not exists in the filter panel");
			}
		}
	}

	
	/**
	 * 
	 * @param data
	 * @throws IOException
	 * @throws InterruptedException
	 */
	public void setDFStatusCodeFilter(String DFStatusCode) throws IOException, InterruptedException {
		if (!DFStatusCode.equals("-1")) {
			if (func.getElement(By.xpath("//span[text()='Dynamic Fields']")).isDisplayed()) {
				WebElement element = driver.findElement(By.xpath("//span[text()='Dynamic Fields']/span"));
				if (element.getAttribute("class").contains("right")) func.getElement(By.xpath("//span[text()='Dynamic Fields']/span")).click();			
				if (func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "_DynamicFields button.dynamicFieldFilterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).isDisplayed()) {
					func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "_DynamicFields button.dynamicFieldFilterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).click();
					if (func.getElement(By.xpath("//a[contains(text(),'Status Code')]")).isDisplayed()) {
						func.getElement(By.xpath("//a[contains(text(),'Status Code')]")).click();	
					}					
					func.getElement(By.cssSelector("button.btn.btn-secondary.btn-xs")).click();
					
					if (func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "_DF_6_StatusCode button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).isDisplayed()) {
						String[] temp = DFStatusCode.split(";");
						func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "_DF_6_StatusCode button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).click();
						for (int i=0; i<temp.length;i++) {				
							if (func.getElement(By.xpath("//input[@name='" +  getStringConfigData("client") + "_DF_6_StatusCode' and @value='" + temp[i].trim() + "']")).isDisplayed()) {
								func.getElement(By.xpath("//input[@name='" +  getStringConfigData("client") + "_DF_6_StatusCode' and @value='" + temp[i].trim() + "']")).click();	
						    	report.success("Action", "[Filter] DF StatusCode: " + temp[i].trim());
							}		
						}
						func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "_DF_6_StatusCode button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).click();
					}
				}
			} else {
		    	report.error("Message", "[Filter] DF Status Code filter not exists in the filter panel");
			}
		}
	}


	/**
	 * 
	 * @param data
	 * @throws IOException
	 * @throws InterruptedException
	 */
	public void setDFClaimNumberFilter(String DFClaimNumber) throws IOException, InterruptedException {
		if (!DFClaimNumber.equals("-1")) {
			if (func.getElement(By.xpath("//span[text()='Dynamic Fields']")).isDisplayed()) {
				WebElement element = driver.findElement(By.xpath("//span[text()='Dynamic Fields']/span"));
				if (element.getAttribute("class").contains("right")) func.getElement(By.xpath("//span[text()='Dynamic Fields']/span")).click();			
				if (func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "_DynamicFields button.dynamicFieldFilterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).isDisplayed()) {
					func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "_DynamicFields button.dynamicFieldFilterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).click();
					if (func.getElement(By.xpath("//a[contains(text(),'Claim Number')]")).isDisplayed()) {
						func.getElement(By.xpath("//a[contains(text(),'Claim Number')]")).click();	
					}					
					func.getElement(By.cssSelector("button.btn.btn-secondary.btn-xs")).click();
					
					if (func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "_DF_7_ClaimNumber button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).isDisplayed()) {
						String[] temp = DFClaimNumber.split(";");
						func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "_DF_7_ClaimNumber button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).click();
						for (int i=0; i<temp.length;i++) {				
							if (func.getElement(By.xpath("//input[@name='" +  getStringConfigData("client") + "_DF_7_ClaimNumber' and @value='" + temp[i].trim() + "']")).isDisplayed()) {
								func.getElement(By.xpath("//input[@name='" +  getStringConfigData("client") + "_DF_7_ClaimNumber' and @value='" + temp[i].trim() + "']")).click();	
						    	report.success("Action", "[Filter] DF Claim Number: " + temp[i].trim());
							}		
						}
						func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "_DF_7_ClaimNumber button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).click();
					}
				}
			} else {
		    	report.error("Message", "[Filter] DF Claim Number filter not exists in the filter panel");
			}
		}
	}


	/**
	 * 
	 * @param data
	 * @throws IOException
	 * @throws InterruptedException
	 */
	public void setDFGBBranchNameFilter(String DFGBBranchName) throws IOException, InterruptedException {
		if (!DFGBBranchName.equals("-1")) {
			if (func.getElement(By.xpath("//span[text()='Dynamic Fields']")).isDisplayed()) {
				WebElement element = driver.findElement(By.xpath("//span[text()='Dynamic Fields']/span"));
				if (element.getAttribute("class").contains("right")) func.getElement(By.xpath("//span[text()='Dynamic Fields']/span")).click();			
				if (func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "_DynamicFields button.dynamicFieldFilterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).isDisplayed()) {
					func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "_DynamicFields button.dynamicFieldFilterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).click();
					if (func.getElement(By.xpath("//a[contains(text(),'GB Branch Name')]")).isDisplayed()) {
						func.getElement(By.xpath("//a[contains(text(),'GB Branch Name')]")).click();	
					}					
					func.getElement(By.cssSelector("button.btn.btn-secondary.btn-xs")).click();
					
					if (func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "_DF_8_GBBranchName button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).isDisplayed()) {
						String[] temp = DFGBBranchName.split(";");
						func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "_DF_8_GBBranchName button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).click();
						for (int i=0; i<temp.length;i++) {				
							if (func.getElement(By.xpath("//input[@name='" +  getStringConfigData("client") + "_DF_8_GBBranchName' and @value='" + temp[i].trim() + "']")).isDisplayed()) {
								func.getElement(By.xpath("//input[@name='" +  getStringConfigData("client") + "_DF_8_GBBranchName' and @value='" + temp[i].trim() + "']")).click();	
						    	report.success("Action", "[Filter] DF GB Branch Name: " + temp[i].trim());
							}		
						}
						func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "_DF_8_GBBranchName button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).click();
					}
				}
			} else {
		    	report.error("Message", "[Filter] DF GB Branch Name filter not exists in the filter panel");
			}
		}
	}
	
	
	/**
	 * 
	 * @param data
	 * @throws IOException
	 * @throws InterruptedException
	 */
	public void setDFGBBranchNumberFilter(String DFGBBranchNumber) throws IOException, InterruptedException {
		if (!DFGBBranchNumber.equals("-1")) {
			if (func.getElement(By.xpath("//span[text()='Dynamic Fields']")).isDisplayed()) {
				WebElement element = driver.findElement(By.xpath("//span[text()='Dynamic Fields']/span"));
				if (element.getAttribute("class").contains("right")) func.getElement(By.xpath("//span[text()='Dynamic Fields']/span")).click();			
				if (func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "_DynamicFields button.dynamicFieldFilterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).isDisplayed()) {
					func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "_DynamicFields button.dynamicFieldFilterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).click();
					if (func.getElement(By.xpath("//a[contains(text(),'GB Branch Number')]")).isDisplayed()) {
						func.getElement(By.xpath("//a[contains(text(),'GB Branch Number')]")).click();	
					}					
					func.getElement(By.cssSelector("button.btn.btn-secondary.btn-xs")).click();
					
					if (func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "_DF_9_GBBranchNumber button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).isDisplayed()) {
						String[] temp = DFGBBranchNumber.split(";");
						func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "_DF_9_GBBranchNumber button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).click();
						for (int i=0; i<temp.length;i++) {				
							if (func.getElement(By.xpath("//input[@name='" +  getStringConfigData("client") + "_DF_9_GBBranchNumber' and @value='" + temp[i].trim() + "']")).isDisplayed()) {
								func.getElement(By.xpath("//input[@name='" +  getStringConfigData("client") + "_DF_9_GBBranchNumber' and @value='" + temp[i].trim() + "']")).click();	
						    	report.success("Action", "[Filter] DF GB Branch Number: " + temp[i].trim());
							}		
						}
						func.getElement(By.cssSelector("div.dropdown.dropdown_" + getStringConfigData("client") + "_DF_9_GBBranchNumber button.filterDropDownButtonStyle.form-control.dropdown-toggle.text-left")).click();
					}
				}
			} else {
		    	report.error("Message", "[Filter] DF GB Branch Number filter not exists in the filter panel");
			}
		}
	}

}
