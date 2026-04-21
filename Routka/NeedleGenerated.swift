

import MapKit
import NeedleFoundation
import SimpleRouter
import SwiftData
import SwiftUI
import vladukhaAlerts

// swiftlint:disable unused_declaration
private let needleDependenciesHash : String? = nil

// MARK: - Traversal Helpers

private func parent1(_ component: NeedleFoundation.Scope) -> NeedleFoundation.Scope {
    return component.parent
}

private func parent2(_ component: NeedleFoundation.Scope) -> NeedleFoundation.Scope {
    return component.parent.parent
}

private func parent3(_ component: NeedleFoundation.Scope) -> NeedleFoundation.Scope {
    return component.parent.parent.parent
}

// MARK: - Providers

#if !NEEDLE_DYNAMIC

private class RootDependency3944cc797a4a88956fb5Provider: RootDependency {
    var tabRouter: any TabRouterProtocol {
        return appComponent.tabRouter
    }
    var routers: [String: Router] {
        return appComponent.routers
    }
    private let appComponent: AppComponent
    init(appComponent: AppComponent) {
        self.appComponent = appComponent
    }
}
/// ^->AppComponent->RootComponent
private func factory264bfc4d4cb6b0629b40f47b58f8f304c97af4d5(_ component: NeedleFoundation.Scope) -> AnyObject {
    return RootDependency3944cc797a4a88956fb5Provider(appComponent: parent1(component) as! AppComponent)
}
private class TrackMapDependencyb7df5df670b4876115d1Provider: TrackMapDependency {
    var locationService: any LocationServiceProtocol {
        return mockTrackMapDetailParentComponent.locationService
    }
    private let mockTrackMapDetailParentComponent: MockTrackMapDetailParentComponent
    init(mockTrackMapDetailParentComponent: MockTrackMapDetailParentComponent) {
        self.mockTrackMapDetailParentComponent = mockTrackMapDetailParentComponent
    }
}
/// ^->MockTrackMapDetailParentComponent->TrackMapComponent
private func factory6c4694b1def835eff0108adf4a46b14b88d9ed11(_ component: NeedleFoundation.Scope) -> AnyObject {
    return TrackMapDependencyb7df5df670b4876115d1Provider(mockTrackMapDetailParentComponent: parent1(component) as! MockTrackMapDetailParentComponent)
}
private class TrackMapDependency1439b8685067f241a32fProvider: TrackMapDependency {
    var locationService: any LocationServiceProtocol {
        return appComponent.locationService
    }
    private let appComponent: AppComponent
    init(appComponent: AppComponent) {
        self.appComponent = appComponent
    }
}
/// ^->AppComponent->RootComponent->TrackDetailComponent->TrackMapComponent
private func factory92921049afcc56cdfef9b2702fa908b4cedb8464(_ component: NeedleFoundation.Scope) -> AnyObject {
    return TrackMapDependency1439b8685067f241a32fProvider(appComponent: parent3(component) as! AppComponent)
}
private class TrackDetailDependencyddd498ef0007fd5f0f2dProvider: TrackDetailDependency {
    var storageService: any TrackStorageProtocol {
        return appComponent.storageService
    }
    var tabRouter: any TabRouterProtocol {
        return appComponent.tabRouter
    }
    var routers: [String: Router] {
        return appComponent.routers
    }
    var trackFileService: any TrackFileServiceProtocol {
        return appComponent.trackFileService
    }
    var trackReplayCoordinator: any TrackReplayCoordinatorProtocol {
        return appComponent.trackReplayCoordinator
    }
    private let appComponent: AppComponent
    init(appComponent: AppComponent) {
        self.appComponent = appComponent
    }
}
/// ^->AppComponent->RootComponent->TrackDetailComponent
private func factory6a7786d3f8384db89491b7304b634b3e62c64b3c(_ component: NeedleFoundation.Scope) -> AnyObject {
    return TrackDetailDependencyddd498ef0007fd5f0f2dProvider(appComponent: parent2(component) as! AppComponent)
}
private class MapSnippetDependency527db8e986ab340d72ecProvider: MapSnippetDependency {
    var mapSnippetCache: any TrackMapSnippetCacheProtocol {
        return appComponent.mapSnippetCache
    }
    var mapSnapshotGenerator: any MapSnapshotGeneratorProtocol {
        return appComponent.mapSnapshotGenerator
    }
    private let appComponent: AppComponent
    init(appComponent: AppComponent) {
        self.appComponent = appComponent
    }
}
/// ^->AppComponent->RootComponent->TrackDetailComponent->MapSnippetComponent
private func factoryd2698b7e2c6f8572ef5db2702fa908b4cedb8464(_ component: NeedleFoundation.Scope) -> AnyObject {
    return MapSnippetDependency527db8e986ab340d72ecProvider(appComponent: parent3(component) as! AppComponent)
}
private class MapSnippetDependency352f54f750948a40ed7bProvider: MapSnippetDependency {
    var mapSnippetCache: any TrackMapSnippetCacheProtocol {
        return mockMapSnippetParentComponent.mapSnippetCache
    }
    var mapSnapshotGenerator: any MapSnapshotGeneratorProtocol {
        return mockMapSnippetParentComponent.mapSnapshotGenerator
    }
    private let mockMapSnippetParentComponent: MockMapSnippetParentComponent
    init(mockMapSnippetParentComponent: MockMapSnippetParentComponent) {
        self.mockMapSnippetParentComponent = mockMapSnippetParentComponent
    }
}
/// ^->MockMapSnippetParentComponent->MapSnippetComponent
private func factory8866217649a5eb73d4929ff55ac03fada00284bc(_ component: NeedleFoundation.Scope) -> AnyObject {
    return MapSnippetDependency352f54f750948a40ed7bProvider(mockMapSnippetParentComponent: parent1(component) as! MockMapSnippetParentComponent)
}

#else
extension AppComponent: NeedleFoundation.Registration {
    public func registerItems() {

        localTable["routers-[String: Router]"] = { [unowned self] in self.routers as Any }
        localTable["storageService-any TrackStorageProtocol"] = { [unowned self] in self.storageService as Any }
        localTable["mapSnippetCache-any TrackMapSnippetCacheProtocol"] = { [unowned self] in self.mapSnippetCache as Any }
        localTable["trackFileService-any TrackFileServiceProtocol"] = { [unowned self] in self.trackFileService as Any }
        localTable["trackReplayCoordinator-any TrackReplayCoordinatorProtocol"] = { [unowned self] in self.trackReplayCoordinator as Any }
        localTable["cacheFileManager-any CacheFileManagerProtocol"] = { [unowned self] in self.cacheFileManager as Any }
        localTable["tabRouter-any TabRouterProtocol"] = { [unowned self] in self.tabRouter as Any }
        localTable["locationService-any LocationServiceProtocol"] = { [unowned self] in self.locationService as Any }
        localTable["mapSnapshotGenerator-any MapSnapshotGeneratorProtocol"] = { [unowned self] in self.mapSnapshotGenerator as Any }
    }
}
extension RootComponent: NeedleFoundation.Registration {
    public func registerItems() {
        keyPathToName[\RootDependency.tabRouter] = "tabRouter-any TabRouterProtocol"
        keyPathToName[\RootDependency.routers] = "routers-[String: Router]"

    }
}
extension TrackMapComponent: NeedleFoundation.Registration {
    public func registerItems() {
        keyPathToName[\TrackMapDependency.locationService] = "locationService-any LocationServiceProtocol"
    }
}
extension MockTrackMapDetailParentComponent: NeedleFoundation.Registration {
    public func registerItems() {

        localTable["locationService-any LocationServiceProtocol"] = { [unowned self] in self.locationService as Any }
    }
}
extension TrackDetailComponent: NeedleFoundation.Registration {
    public func registerItems() {
        keyPathToName[\TrackDetailDependency.storageService] = "storageService-any TrackStorageProtocol"
        keyPathToName[\TrackDetailDependency.tabRouter] = "tabRouter-any TabRouterProtocol"
        keyPathToName[\TrackDetailDependency.routers] = "routers-[String: Router]"
        keyPathToName[\TrackDetailDependency.trackFileService] = "trackFileService-any TrackFileServiceProtocol"
        keyPathToName[\TrackDetailDependency.trackReplayCoordinator] = "trackReplayCoordinator-any TrackReplayCoordinatorProtocol"

    }
}
extension MapSnippetComponent: NeedleFoundation.Registration {
    public func registerItems() {
        keyPathToName[\MapSnippetDependency.mapSnippetCache] = "mapSnippetCache-any TrackMapSnippetCacheProtocol"
        keyPathToName[\MapSnippetDependency.mapSnapshotGenerator] = "mapSnapshotGenerator-any MapSnapshotGeneratorProtocol"
    }
}
extension MockMapSnippetParentComponent: NeedleFoundation.Registration {
    public func registerItems() {

        localTable["mapSnippetCache-any TrackMapSnippetCacheProtocol"] = { [unowned self] in self.mapSnippetCache as Any }
        localTable["mapSnapshotGenerator-any MapSnapshotGeneratorProtocol"] = { [unowned self] in self.mapSnapshotGenerator as Any }
    }
}


#endif

private func factoryEmptyDependencyProvider(_ component: NeedleFoundation.Scope) -> AnyObject {
    return EmptyDependencyProvider(component: component)
}

// MARK: - Registration
private func registerProviderFactory(_ componentPath: String, _ factory: @escaping (NeedleFoundation.Scope) -> AnyObject) {
    __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: componentPath, factory)
}

#if !NEEDLE_DYNAMIC

@inline(never) private func register1() {
    registerProviderFactory("^->AppComponent", factoryEmptyDependencyProvider)
    registerProviderFactory("^->AppComponent->RootComponent", factory264bfc4d4cb6b0629b40f47b58f8f304c97af4d5)
    registerProviderFactory("^->MockTrackMapDetailParentComponent->TrackMapComponent", factory6c4694b1def835eff0108adf4a46b14b88d9ed11)
    registerProviderFactory("^->AppComponent->RootComponent->TrackDetailComponent->TrackMapComponent", factory92921049afcc56cdfef9b2702fa908b4cedb8464)
    registerProviderFactory("^->MockTrackMapDetailParentComponent", factoryEmptyDependencyProvider)
    registerProviderFactory("^->AppComponent->RootComponent->TrackDetailComponent", factory6a7786d3f8384db89491b7304b634b3e62c64b3c)
    registerProviderFactory("^->AppComponent->RootComponent->TrackDetailComponent->MapSnippetComponent", factoryd2698b7e2c6f8572ef5db2702fa908b4cedb8464)
    registerProviderFactory("^->MockMapSnippetParentComponent->MapSnippetComponent", factory8866217649a5eb73d4929ff55ac03fada00284bc)
    registerProviderFactory("^->MockMapSnippetParentComponent", factoryEmptyDependencyProvider)
}
#endif

public func registerProviderFactories() {
#if !NEEDLE_DYNAMIC
    register1()
#endif
}
