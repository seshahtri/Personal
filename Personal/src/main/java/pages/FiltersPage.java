package pages;

import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;

public class FiltersPage {
	
	public WebDriver driver;
	
	public FiltersPage(WebDriver driver) {
		this.driver = driver;	
	}	

	private By filterExpansionButton = By.cssSelector("#athena > div > div:nth-child(1) > div.globalFilterCollapsed > span > svg");
	public By filterExpansionButton() {
		return filterExpansionButton;
	}	

	private By globalFilterPanelList = By.xpath("//*[@id=\"athena\"]/div/div[1]/div[1]/ul/li");
	public By globalFilterPanelList() {
		return globalFilterPanelList;
	}		

	private By savedFilterPanelDropDown = By.xpath("//div[@class='savedFilterDropdownPlaceHolder']");
	public By savedFilterPanelDropDown() {
		return savedFilterPanelDropDown;
	}	
	
	private By savedFilterPanelList = By.xpath("//div[@class='radioFilter dropdown-menu filterDropdownStyle']/div");
	public By savedFilterPanelList() {
		return savedFilterPanelList;
	}
	
	private By savedFilterCreateNewViewIcon = By.xpath("//span[@class='glyphicon glyphicon-plus']");
	public By savedFilterCreateNewViewIcon() {
		return savedFilterCreateNewViewIcon;
	}	
	
	private By savedFilterCreateNewViewNameText = By.xpath("(//input[@class='filterTextBoxStyle form-control'])");
	public By savedFilterCreateNewViewNameText() {
		return savedFilterCreateNewViewNameText;
	}	
	
	private By savedFilterCreateNewViewDescriptionText = By.xpath("(//textarea[@class='filterTextBoxStyle form-control'])[1]");
	public By savedFilterCreateNewViewDescriptionText() {
		return savedFilterCreateNewViewDescriptionText;
	}	
	
	private By savedFilterCreateNewViewSetDefaultCheck = By.xpath("(//span[@class='savedViewsLabel'])[4]/input");
	public By savedFilterCreateNewViewSetDefaultCheck() {
		return savedFilterCreateNewViewSetDefaultCheck;
	}	
	
	private By savedFilterCreateNewViewCreateButton = By.xpath("//input[@value='Create']");
	public By savedFilterCreateNewViewCreateButton() {
		return savedFilterCreateNewViewCreateButton;
	}
	
	private By savedFilterEditViewIcon = By.xpath("//a[@id='save']");
	public By savedFilterEditViewIcon() {
		return savedFilterEditViewIcon;
	}	
	
	private By savedFilterEditViewNameText = By.xpath("(//input[@class='filterTextBoxStyle form-control'])");
	public By savedFilterEditViewNameText() {
		return savedFilterEditViewNameText;
	}	
	
	private By savedFilterEditViewDescriptionText = By.xpath("(//textarea[@class='filterTextBoxStyle form-control'])[2]");
	public By savedFilterEditViewDescriptionText() {
		return savedFilterEditViewDescriptionText;
	}	
	
	private By savedFilterEditViewSetDefaultCheck = By.xpath("(//span[@class='savedViewsLabel'])[8]/input");
	public By savedFilterEditViewSetDefaultCheck() {
		return savedFilterEditViewSetDefaultCheck;
	}	
	
	private By savedFilterEditViewUpdateButton = By.xpath("//input[@value='Update']");
	public By savedFilterEditViewUpdateButton() {
		return savedFilterEditViewUpdateButton;
	}
	
	private By savedFilterDeleteViewButton = By.xpath("//a[@id='delete']");
	public By savedFilterDeleteViewButton() {
		return savedFilterDeleteViewButton;
	}
	
	private By savedFilterDeleteViewDeleteButton = By.xpath("//input[@value='Delete']");
	public By savedFilterDeleteViewDeleteButton() {
		return savedFilterDeleteViewDeleteButton;
	}
	
}

