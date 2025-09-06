package generalplus.com.GPCamLib;

import android.util.Log;

import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

import java.io.File;
import java.util.ArrayList;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;

import org.xml.sax.SAXException;

import java.io.IOException;


public class GPXMLParse {

    public final static int CategoryLevel = 12;
    public final static int SettingLevel = 6;
    public final static int ValueLevel = 0;

    // Item Index
    public final static int RecordResolution_Setting_ID = 0x00000000;
    public final static int CaptureResolution_Setting_ID = 0x00000100;
    public final static int Version_Setting_ID = 0x00000209;
    public final static int Version_Value_Index = 0;

    private GPXMLValue m_GPXMLValue;
    private GPXMLSetting m_GPXMLSetting;
    private GPXMLCategory m_GPXMLCategory;

    private static final ArrayList<GPXMLValue> m_aryListGPXMLValues = new ArrayList<>();
    private static final ArrayList<GPXMLSetting> m_aryListGPXMLSettings = new ArrayList<>();
    private static final ArrayList<GPXMLCategory> m_aryListGPXMLCategroies = new ArrayList<>();

    private final static String GPTag = "GPXMLParseLog";

    public ArrayList<GPXMLCategory> GetCategories() {
        synchronized (m_aryListGPXMLValues) {
            m_aryListGPXMLValues.clear();
        }
        synchronized (m_aryListGPXMLSettings) {
            m_aryListGPXMLSettings.clear();
        }
        synchronized (m_aryListGPXMLCategroies) {
            m_aryListGPXMLCategroies.clear();
            return m_aryListGPXMLCategroies;
        }
    }

    public class GPXMLValue {
        public String strXMLValueName;
        public String strXMLValueID;
        public int i32TreeLevel;

        public GPXMLValue(String ValueName, String ValueID, int TreeLevel) {
            this.strXMLValueName = ValueName;
            this.strXMLValueID = ValueID;
            this.i32TreeLevel = TreeLevel;
        }
    }

    public class GPXMLSetting {
        public String strXMLSettingName;
        public String strXMLSettingID;
        public String strXMLSettingType;
        public String strXMLSettingReflash;
        public String strXMLSettingDefaultValue;
        public String strXMLSettingCurrent = null;
        public int i32TreeLevel;
        public ArrayList<GPXMLValue> aryListGPXMLValues;

        public GPXMLSetting(String SettingName, String SettingID, String SettingType, String SettingReflash,
                            String SettingDefaultValue, int TreeLevel, ArrayList<GPXMLValue> XMLValue) {
            this.strXMLSettingName = SettingName;
            this.strXMLSettingID = SettingID;
            this.strXMLSettingType = SettingType;
            this.strXMLSettingReflash = SettingReflash;
            this.strXMLSettingDefaultValue = SettingDefaultValue;
            if (XMLValue != null) {
                for (GPXMLValue value : XMLValue) {
                    if (value.strXMLValueID.equalsIgnoreCase(SettingDefaultValue)) {
                        this.strXMLSettingCurrent = value.strXMLValueName;
                        break;
                    }
                }
            }
            this.i32TreeLevel = TreeLevel;
            if (XMLValue != null) {
                this.aryListGPXMLValues = (ArrayList<GPXMLValue>) XMLValue.clone();
            } else {
                this.aryListGPXMLValues = new ArrayList<>();
            }
        }
    }

    public class GPXMLCategory {
        public String strXMLCategoryName;
        public int i32TreeLevel;
        public ArrayList<GPXMLSetting> aryListGPXMLSettings;

        public GPXMLCategory(String CategoryName, int TreeLevel, ArrayList<GPXMLSetting> XMLSetting) {
            this.strXMLCategoryName = CategoryName;
            this.i32TreeLevel = TreeLevel;
            this.aryListGPXMLSettings = (ArrayList<GPXMLSetting>) XMLSetting.clone();
        }
    }

    public ArrayList<GPXMLCategory> GetGPXMLInfo(String FilePath) {
        try {
            File xmlFile = new File(FilePath);
            DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();

            factory.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
            factory.setFeature("http://xml.org/sax/features/external-general-entities", false);
            factory.setFeature("http://xml.org/sax/features/external-parameter-entities", false);
            factory.setFeature("http://apache.org/xml/features/nonvalidating/load-external-dtd", false);

            factory.setXIncludeAware(false);
            factory.setExpandEntityReferences(false);

            DocumentBuilder builder = factory.newDocumentBuilder();
            Document doc = builder.parse(xmlFile);

            NodeList nodeList_Categories = doc.getElementsByTagName("Categories");

            m_aryListGPXMLCategroies.clear();

            for (int i32CategoriesIndex = 0; i32CategoriesIndex < nodeList_Categories.getLength(); i32CategoriesIndex++) {
                Node node_Categories = nodeList_Categories.item(i32CategoriesIndex);
                if (node_Categories.getNodeType() == Node.ELEMENT_NODE) {
                    Element element_Categories = (Element) node_Categories;
                    NodeList nodeList_Category = element_Categories.getElementsByTagName("Category");

                    for (int i32CategoryIndex = 0; i32CategoryIndex < nodeList_Category.getLength(); i32CategoryIndex++) {
                        Node node_Category = nodeList_Category.item(i32CategoryIndex);
                        if (node_Category.getNodeType() == Node.ELEMENT_NODE) {
                            Element element_Category = (Element) node_Category;
                            synchronized (m_aryListGPXMLSettings) {
                                m_aryListGPXMLSettings.clear();
                            }

                            String strCategoryName = getNodeValue(element_Category, "Name");

                            NodeList nodeList_Settings = element_Category.getElementsByTagName("Settings");
                            for (int i32SettingsIndex = 0; i32SettingsIndex < nodeList_Settings.getLength(); i32SettingsIndex++) {
                                Node node_Settings = nodeList_Settings.item(i32SettingsIndex);
                                if (node_Settings.getNodeType() == Node.ELEMENT_NODE) {
                                    Element element_Settings = (Element) node_Settings;
                                    NodeList nodeList_Setting = element_Settings.getElementsByTagName("Setting");

                                    for (int i32SettingIndex = 0; i32SettingIndex < nodeList_Setting.getLength(); i32SettingIndex++) {
                                        Node node_Setting = nodeList_Setting.item(i32SettingIndex);
                                        if (node_Setting.getNodeType() == Node.ELEMENT_NODE) {
                                            Element element_Setting = (Element) node_Setting;

                                            if (m_aryListGPXMLValues != null) {
                                                synchronized (m_aryListGPXMLValues) {
                                                    m_aryListGPXMLValues.clear();
                                                }
                                            }

                                            String strSettingName = getNodeValue(element_Setting, "Name");
                                            String strSettingID = getNodeValue(element_Setting, "ID");
                                            String strSettingType = getNodeValue(element_Setting, "Type");
                                            String strSettingReflash = getNodeValue(element_Setting, "Reflash");
                                            String strSettingDefault = getNodeValue(element_Setting, "Default");

                                            NodeList nodeList_Values = element_Setting.getElementsByTagName("Values");
                                            for (int i32ValuesIndex = 0; i32ValuesIndex < nodeList_Values.getLength(); i32ValuesIndex++) {
                                                Node node_Values = nodeList_Values.item(i32ValuesIndex);
                                                if (node_Values.getNodeType() == Node.ELEMENT_NODE) {
                                                    Element element_Values = (Element) node_Values;
                                                    NodeList nodeList_Value = element_Values.getElementsByTagName("Value");

                                                    for (int i32ValueIndex = 0; i32ValueIndex < nodeList_Value.getLength(); i32ValueIndex++) {
                                                        Node node_Value = nodeList_Value.item(i32ValueIndex);
                                                        if (node_Value.getNodeType() == Node.ELEMENT_NODE) {
                                                            Element element_Value = (Element) node_Value;
                                                            String strValueName = getNodeValue(element_Value, "Name");
                                                            String strValueID = getNodeValue(element_Value, "ID");

                                                            m_GPXMLValue = new GPXMLValue(strValueName, strValueID,
                                                                    (i32CategoryIndex * (1 << CategoryLevel)) +
                                                                            (i32SettingIndex * (1 << SettingLevel)) +
                                                                            (i32ValueIndex * (1 << ValueLevel)));

                                                            if (m_GPXMLValue != null && m_aryListGPXMLValues != null) {
                                                                synchronized (m_aryListGPXMLValues) {
                                                                    m_aryListGPXMLValues.add(m_GPXMLValue);
                                                                }
                                                            }

                                                            m_GPXMLValue = null;
                                                        }
                                                    }
                                                }
                                            }

                                            m_GPXMLSetting = new GPXMLSetting(strSettingName, strSettingID, strSettingType, strSettingReflash,
                                                    strSettingDefault, (i32CategoryIndex << CategoryLevel | i32SettingIndex << SettingLevel),
                                                    m_aryListGPXMLValues);

                                            synchronized (m_aryListGPXMLSettings) {
                                                m_aryListGPXMLSettings.add(m_GPXMLSetting);
                                            }
                                            m_GPXMLSetting = null;
                                        }
                                    }
                                }
                            }

                            m_GPXMLCategory = new GPXMLCategory(strCategoryName, (i32CategoryIndex << CategoryLevel), m_aryListGPXMLSettings);

                            synchronized (m_aryListGPXMLCategroies) {
                                m_aryListGPXMLCategroies.add(m_GPXMLCategory);
                            }
                            m_GPXMLCategory = null;
                        }
                    }
                }
            }

        } catch (ParserConfigurationException pce) {
            Log.e(GPTag, "XML 파서 구성 오류", pce);
            // 필요 시 상위로 전파
        } catch (SAXException saxe) {
            Log.e(GPTag, "XML 파싱 오류", saxe);
            // 필요 시 상위로 전파
        } catch (IOException ioe) {
            Log.e(GPTag, "XML 파일 입출력 오류", ioe);
            // 필요 시 상위로 전파
        } catch (NullPointerException npe) {
            Log.e(GPTag, "XML 파싱 중 NullPointerException 발생", npe);
            // 필요 시 상위로 전파
        } catch (Exception e) {
            Log.e(GPTag, "XML 파싱 중 알 수 없는 오류", e);
            // 필요 시 상위로 전파
        }

        synchronized (m_aryListGPXMLCategroies) {
            return m_aryListGPXMLCategroies;
        }
    }

    private String getNodeValue(Element parent, String tagName) {
        NodeList nodeList = parent.getElementsByTagName(tagName);
        if (nodeList.getLength() > 0 && nodeList.item(0).getFirstChild() != null) {
            return nodeList.item(0).getFirstChild().getNodeValue();
        }
        return "";
    }
}
