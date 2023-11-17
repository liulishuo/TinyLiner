

import UIKit

class LogChartViewController: UIViewController {
    
    let aaChartView = AAChartView()
    
    var lines = [JSON]()
    var lineIndex = [String: Int]()
    
    var points = [String: JSON]()
    var pointExtData = [String: [String: String]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "埋点Log"
        
        TinyLiner.shared.dump { [weak self] array in
            
            guard let array = array else {
                return
            }
            
            for string in array {
                let json = JSON(parseJSON: string)
                
                if json["eTime"].double != nil {
                    if let name = json["id"].string {
                        self?.lineIndex[name] = self?.lines.count
                        self?.lines.append(json)
                    }
                } else if let preId = json["preId"].string {
                    self?.points[preId] = json
                    self?.pointExtData[json["id"].stringValue] = json["ext"].dictionaryObject as? [String: String]
                }
            }
            
            DispatchQueue.main.async {
                self?.addChart()
                self?.configureColumnrangeChart()
            }
            
        }
    }
    
    func configureColumnrangeChart() {
        let maxTime = Date().timeIntervalSince1970
        
        let categories = lines.compactMap { json in
            if let s = json["id"].string {
                if s.count > 5 {
                    let sIndex = s.startIndex
                    let eIndex = s.index(sIndex, offsetBy: 5)
                    let res = String(s[sIndex...eIndex])
                    return res
                }
                
                return s
            }
            
            return nil
        }
        
        let linesData = lines.compactMap { json in
            [json["sTime"].doubleValue, json["eTime"].doubleValue]
        }
        
        let pointsData = points.compactMap { [weak self] (_, json) in
            if let name = json["id"].string, let ts = json["ts"].double, let preId = json["preId"].string {
                let point = AASeriesElement()
                    .name(name)
                    .type(.scatter)
                if let count = self?.lineIndex[preId] {
                    let gap: [Any] = Array(repeating: NSNull(), count: count)
                    let data = gap + [ts]
                    point.data(data)
                } else {
                    point.data([ts])
                }
                
                return point
            }
            
            return nil
        }
        
        let seriesData = [AASeriesElement()
            .name("")
            .data(linesData)
            .pointPadding(0.05)
            .borderRadius(5)
            .showInLegend(false)] + pointsData
        
        let aaChartModel = AAChartModel()
            .chartType(.columnrange)
            .zoomType(.xy)
            .yAxisMax(maxTime)
            .yAxisGridLineWidth(0)
            .scrollablePlotArea(
                AAScrollablePlotArea()
                    .minWidth(1000)
                    .scrollPositionX(0)
            )
            .categories(categories)
            .dataLabelsEnabled(false)
            .inverted(true)// x 轴是否垂直翻转
            .series(seriesData)
        
        let aaOptions = aaChartModel.aa_toAAOptions()
        
        var extString = ""
        if let jsonData = try? JSONSerialization.data(withJSONObject: pointExtData, options: JSONSerialization.WritingOptions.init(rawValue: 0)),
           let jsonString = String(data: jsonData, encoding: String.Encoding.utf8) {
            extString = jsonString
        }
        
        aaOptions.tooltip?
            .shared(false)
            .formatter("""
            function () {
                if (this.series.name === "") {
                    return this.x;
                }
                let obj = \(extString)[this.series.name];
                let des = '';
                for (let key in obj) {
                    des += key + ': ' + obj[key] + '<br/>';
                };
                return '<b>'
                + this.x
                + '.'
                + this.series.name
                + '</b><br/>'
                + '<br/>'
                + des
                + '<br/>';
            }
            """)
        
        let aaCrosshair = AACrosshair()
            .color("#000000")
            .dashStyle(.longDashDotDot)
            .width(2)
            .zIndex(10)
        
        aaOptions.xAxis?.crosshair(aaCrosshair)
        aaOptions.yAxis?.crosshair(aaCrosshair)
        
        aaOptions.yAxis?
            .type(.datetime)
            .dateTimeLabelFormats(
                AADateTimeLabelFormats().millisecond("%H:%M:%S.%L"))
        
        aaChartView.aa_drawChartWithChartOptions(aaOptions)
    }
    
    func addChart() {
        aaChartView.isScrollEnabled = false
        view.addSubview(aaChartView)
        
        aaChartView.translatesAutoresizingMaskIntoConstraints = false
        aaChartView.scrollView.contentInsetAdjustmentBehavior = .never
        view.addConstraints([
            NSLayoutConstraint(item: aaChartView,
                               attribute: .left,
                               relatedBy: .equal,
                               toItem: view,
                               attribute: .left,
                               multiplier: 1,
                               constant: 0),
            NSLayoutConstraint(item: aaChartView,
                               attribute: .right,
                               relatedBy: .equal,
                               toItem: view,
                               attribute: .right,
                               multiplier: 1,
                               constant: 0),
            NSLayoutConstraint(item: aaChartView,
                               attribute: .top,
                               relatedBy: .equal,
                               toItem: view,
                               attribute: .top,
                               multiplier: 1,
                               constant: 0),
            NSLayoutConstraint(item: aaChartView,
                               attribute: .bottom,
                               relatedBy: .equal,
                               toItem: view,
                               attribute: .bottom,
                               multiplier: 1,
                               constant: 0)
        ])
    }
}
