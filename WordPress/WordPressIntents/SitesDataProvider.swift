import Intents

class SitesDataProvider {
    private(set) var sites = [Site]()

    init() {
        initializeSites()
    }

    // MARK: - Init Support

    private func initializeSites() {
        guard let data = HomeWidgetTodayData.read() else {
            sites = []
            return
        }

        sites = data.map { (key: Int, data: HomeWidgetTodayData) -> Site in

            // Note: the image for the site was being set through:
            //
            // icon(from: data)
            //
            // Unfortunately, this had to be turned off for now since images aren't working very well in the
            // customizer as reported here: https://github.com/wordpress-mobile/WordPress-iOS/pull/15397#pullrequestreview-539474644

            let siteDomain: String?

            if let urlComponents = URLComponents(string: data.url),
               let host = urlComponents.host {

                siteDomain = host
            } else {
                siteDomain = nil
            }

            return Site(
                identifier: String(key),
                display: data.siteName,
                subtitle: siteDomain,
                image: nil)
        }.sorted(by: { $0.displayString.lowercased() < $1.displayString.lowercased() })
    }

    // MARK: - Default Site

    private var defaultSiteID: Int? {
        // TODO - TODAYWIDGET: taking the default site id from user defaults for now.
        // This would change if the old widget gets reconfigured to a different site than the default.
        return UserDefaults(suiteName: WPAppGroupName)?.object(forKey: WPStatsTodayWidgetUserDefaultsSiteIdKey) as? Int
    }

    var defaultSite: Site? {
        guard let defaultSiteID = self.defaultSiteID else {
            return nil
        }

        return sites.first { site in
            return site.identifier == String(defaultSiteID)
        }
    }

    // MARK: - Site Icons

    private func icon(from data: HomeWidgetTodayData) -> INImage {
        guard let iconURL = data.iconURL,
              let url = URL(string: iconURL),
              let image = INImage(url: url) else {

            return INImage(named: "blavatar-default")
        }

        return image
    }
}
