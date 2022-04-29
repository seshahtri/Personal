package pages;

import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;

public class VizPage {
	
	public WebDriver driver;
	
	public VizPage(WebDriver driver) {
		this.driver = driver;	
	}	
	
	private By iframeChart = By.xpath("//div[@id='chart']//iframe");
	public By iframeChart() {
		return iframeChart;
	}	
	
	private By iframeTable = By.xpath("//div[@id='table']//iframe");
	public By iframeTable() {
		return iframeTable;
	}	

	private By canvas = By.xpath("//*[contains(@id,'view')]//canvas[2]");
	public By canvas() {
		return canvas;
	}	
	
	private By spinner = By.xpath("//*[@id=\"svg-spinner\"]");
	public By spinner() {
		return spinner;
	}	

	private By btnView = By.cssSelector("#athena > div > div.page-header.hidden-print > div.headerElements > div > button");
	public By btnView() {
		return btnView;
	}	
	
	private By listChart = By.cssSelector("#athena > div > div.page-header.hidden-print > div.headerElements > div > ul > li:nth-child(1) > a > span.dropdown-menu-label");
	public By listChart() {
		return listChart;
	}
	
	private By listTable = By.cssSelector("#athena > div > div.page-header.hidden-print > div.headerElements > div > ul > li:nth-child(2) > a > span.dropdown-menu-label");
	public By listTable() {
		return listTable;
	}

	private By listBoth = By.cssSelector("#athena > div > div.page-header.hidden-print > div.headerElements > div > ul > li:nth-child(3) > a > span.dropdown-menu-label");
	public By listBoth() {
		return listBoth;
	}
	
	private By txtDrillParam = By.cssSelector("#drillDownModal > div > div > div.modal-body.drilldown-menu-div > ul.lu-drilldown-parameters");
	public By txtDrillParam() {
		return txtDrillParam;
	}

	private By linkDrillViz = By.cssSelector("#drillDownModal > div > div > div.modal-body.drilldown-menu-div > ul.lu-drilldown-visualizations");
	public By linkDrillViz() {
		return linkDrillViz;
	}
	
	private By btnExportCSV = By.cssSelector("#athena > div > div.page-header.hidden-print > div.headerElements > button");
	public By btnExportCSV() {
		return btnExportCSV;
	}
	
	private By btnExportAllCSV = By.xpath("//button[text()='Export All CSV']");
	public By btnExportAllCSV() {
		return btnExportAllCSV;
	}
	
	private By btnExportAllExport = By.xpath("//button[text()='Export']");
	public By btnExportAllExport() {
		return btnExportAllExport;
	}
	
	private By btnExportAllClose = By.xpath("//button[text()='Close']");
	public By btnExportAllClose() {
		return btnExportAllClose;
	}
	
	private By btnPrint = By.cssSelector("#app > div > div.wk-react-app.main-navbar-container.wk-block-display-element > nav.navbar.navbar-default.userbar > div > ul.nav.navbar-nav.navbar-right.icon-toolbar > li:nth-child(2) > a");
	public By btnPrint() {
		return btnPrint;
	}
	
	private By txtPrintDrillDown = By.xpath("//*[@id=\"athena\"]/div/div[3]/span");
	public By txtPrintDrillDown() {
		return txtPrintDrillDown;
	}	
	
	private By labelExportAllCSVTitle = By.cssSelector("#exportModalLabel");
	public By labelExportAllCSVTitle() {
		return labelExportAllCSVTitle;
	}	
	
	private By labelExportAllCSVTotalPages = By.cssSelector("span.totalPagesText");
	public By labelExportAllCSVTotalPages() {
		return labelExportAllCSVTotalPages;
	}	
	
	private By btnExportAllCSVPageAfter = By.cssSelector("span.v3pageNext");
	public By btnExportAllCSVPageAfter() {
		return btnExportAllCSVPageAfter;
	}	
	
	private By btnExportAllCSVPagePrev = By.cssSelector("span.v3pagePrev");
	public By btnExportAllCSVPagePrev() {
		return btnExportAllCSVPagePrev;
	}	
	
}
