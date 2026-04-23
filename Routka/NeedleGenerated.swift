

import Combine
import CoreLocation
import Foundation
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

private func parent4(_ component: NeedleFoundation.Scope) -> NeedleFoundation.Scope {
    return component.parent.parent.parent.parent
}

private func parent5(_ component: NeedleFoundation.Scope) -> NeedleFoundation.Scope {
    return component.parent.parent.parent.parent.parent
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
private class TrackPresetsDependencyd183b1fd1768001f1320Provider: TrackPresetsDependency {
    var measuredTrackStorageService: any MeasuredTrackStorageProtocol {
        return appComponent.measuredTrackStorageService
    }
    private let appComponent: AppComponent
    init(appComponent: AppComponent) {
        self.appComponent = appComponent
    }
}
/// ^->AppComponent->RootComponent->BaseMapComponent->TrackPresetsComponent
private func factoryc54fb74f56d2e8aeb21eb2702fa908b4cedb8464(_ component: NeedleFoundation.Scope) -> AnyObject {
    return TrackPresetsDependencyd183b1fd1768001f1320Provider(appComponent: parent3(component) as! AppComponent)
}
private class TracksTabDependencyb619f7697985d5911ed1Provider: TracksTabDependency {
    var storageService: any TrackStorageProtocol {
        return appComponent.storageService
    }
    var measuredTrackStorageService: any MeasuredTrackStorageProtocol {
        return appComponent.measuredTrackStorageService
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
    private let appComponent: AppComponent
    init(appComponent: AppComponent) {
        self.appComponent = appComponent
    }
}
/// ^->AppComponent->RootComponent->TracksTabComponent
private func factoryacee5c99c52fa1d62301b7304b634b3e62c64b3c(_ component: NeedleFoundation.Scope) -> AnyObject {
    return TracksTabDependencyb619f7697985d5911ed1Provider(appComponent: parent2(component) as! AppComponent)
}
private class TrackHistoryDependency73d3e5fbcd00513f8959Provider: TrackHistoryDependency {
    var storageService: any TrackStorageProtocol {
        return appComponent.storageService
    }
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
/// ^->AppComponent->RootComponent->TracksTabComponent->TrackHistoryComponent
private func factoryc63576fc92cbe40690f6b2702fa908b4cedb8464(_ component: NeedleFoundation.Scope) -> AnyObject {
    return TrackHistoryDependency73d3e5fbcd00513f8959Provider(appComponent: parent3(component) as! AppComponent)
}
private class MeasuredTrackDetail41616adfd2d91794a37aProvider: MeasuredTrackDetail {
    var measuredTrackStorageService: any MeasuredTrackStorageProtocol {
        return appComponent.measuredTrackStorageService
    }
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
/// ^->AppComponent->RootComponent->TracksTabComponent->MeasuredTrackDetailComponent
private func factorye99f29e6a1593ff65d10b2702fa908b4cedb8464(_ component: NeedleFoundation.Scope) -> AnyObject {
    return MeasuredTrackDetail41616adfd2d91794a37aProvider(appComponent: parent3(component) as! AppComponent)
}
private class MeasuredTrackDetail6ddb30dff0e32a3e5166Provider: MeasuredTrackDetail {
    var measuredTrackStorageService: any MeasuredTrackStorageProtocol {
        return mockMeasuredTrackDetailComponent.measuredTrackStorageService
    }
    var tabRouter: any TabRouterProtocol {
        return mockMeasuredTrackDetailComponent.tabRouter
    }
    var routers: [String: Router] {
        return mockMeasuredTrackDetailComponent.routers
    }
    private let mockMeasuredTrackDetailComponent: MockMeasuredTrackDetailComponent
    init(mockMeasuredTrackDetailComponent: MockMeasuredTrackDetailComponent) {
        self.mockMeasuredTrackDetailComponent = mockMeasuredTrackDetailComponent
    }
}
/// ^->MockMeasuredTrackDetailComponent->MeasuredTrackDetailComponent
private func factoryd2934ab103e0e67efe9f1ae3ea56d9e8d2e5cbf8(_ component: NeedleFoundation.Scope) -> AnyObject {
    return MeasuredTrackDetail6ddb30dff0e32a3e5166Provider(mockMeasuredTrackDetailComponent: parent1(component) as! MockMeasuredTrackDetailComponent)
}
private class BaseMapDependency7bbe6ed5fa952cf4f036Provider: BaseMapDependency {
    var trackReplayCoordinator: any TrackReplayCoordinatorProtocol {
        return appComponent.trackReplayCoordinator
    }
    var locationService: any LocationServiceProtocol {
        return appComponent.locationService
    }
    var storageService: any TrackStorageProtocol {
        return appComponent.storageService
    }
    var measuredTrackStorageService: any MeasuredTrackStorageProtocol {
        return appComponent.measuredTrackStorageService
    }
    private let appComponent: AppComponent
    init(appComponent: AppComponent) {
        self.appComponent = appComponent
    }
}
/// ^->AppComponent->RootComponent->BaseMapComponent
private func factorybcfd2fbfb73eaddf911db7304b634b3e62c64b3c(_ component: NeedleFoundation.Scope) -> AnyObject {
    return BaseMapDependency7bbe6ed5fa952cf4f036Provider(appComponent: parent2(component) as! AppComponent)
}
private class TrackMapDependency961f5219b3b221b7275eProvider: TrackMapDependency {
    var locationService: any LocationServiceProtocol {
        return appComponent.locationService
    }
    private let appComponent: AppComponent
    init(appComponent: AppComponent) {
        self.appComponent = appComponent
    }
}
/// ^->AppComponent->RootComponent->TracksTabComponent->MeasuredTrackDetailComponent->TrackMapComponent
private func factory75fb5090104e4103bd557586110118823dea9ff0(_ component: NeedleFoundation.Scope) -> AnyObject {
    return TrackMapDependency961f5219b3b221b7275eProvider(appComponent: parent4(component) as! AppComponent)
}
/// ^->AppComponent->RootComponent->TracksTabComponent->TrackHistoryComponent->TrackDetailComponent->TrackMapComponent
private func factory75fb5090104e4103bd559bb8c877c472a171438a(_ component: NeedleFoundation.Scope) -> AnyObject {
    return TrackMapDependency961f5219b3b221b7275eProvider(appComponent: parent5(component) as! AppComponent)
}
private class TrackMapDependency3e941799218268f4a302Provider: TrackMapDependency {
    var locationService: any LocationServiceProtocol {
        return mockMeasuredTrackDetailComponent.locationService
    }
    private let mockMeasuredTrackDetailComponent: MockMeasuredTrackDetailComponent
    init(mockMeasuredTrackDetailComponent: MockMeasuredTrackDetailComponent) {
        self.mockMeasuredTrackDetailComponent = mockMeasuredTrackDetailComponent
    }
}
/// ^->MockMeasuredTrackDetailComponent->MeasuredTrackDetailComponent->TrackMapComponent
private func factorya6144c18161a70cca3b636bfaaf810d08cc605e1(_ component: NeedleFoundation.Scope) -> AnyObject {
    return TrackMapDependency3e941799218268f4a302Provider(mockMeasuredTrackDetailComponent: parent2(component) as! MockMeasuredTrackDetailComponent)
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
private class TrackDetailDependency504c5878bcaa4e782fb6Provider: TrackDetailDependency {
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
/// ^->AppComponent->RootComponent->TracksTabComponent->TrackDetailComponent
private func factory82bfc45ec1872278e5e2b2702fa908b4cedb8464(_ component: NeedleFoundation.Scope) -> AnyObject {
    return TrackDetailDependency504c5878bcaa4e782fb6Provider(appComponent: parent3(component) as! AppComponent)
}
/// ^->AppComponent->RootComponent->TracksTabComponent->TrackHistoryComponent->TrackDetailComponent
private func factory82bfc45ec1872278e5e27586110118823dea9ff0(_ component: NeedleFoundation.Scope) -> AnyObject {
    return TrackDetailDependency504c5878bcaa4e782fb6Provider(appComponent: parent4(component) as! AppComponent)
}
private class MapSnippetDependencye5dfaf46898b43a46047Provider: MapSnippetDependency {
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
/// ^->AppComponent->RootComponent->TracksTabComponent->TrackHistoryCellComponent->MapSnippetComponent
private func factoryd7554d02d94d273d52197586110118823dea9ff0(_ component: NeedleFoundation.Scope) -> AnyObject {
    return MapSnippetDependencye5dfaf46898b43a46047Provider(appComponent: parent4(component) as! AppComponent)
}
/// ^->AppComponent->RootComponent->TracksTabComponent->TrackHistoryComponent->TrackHistoryCellComponent->MapSnippetComponent
private func factoryd7554d02d94d273d52199bb8c877c472a171438a(_ component: NeedleFoundation.Scope) -> AnyObject {
    return MapSnippetDependencye5dfaf46898b43a46047Provider(appComponent: parent5(component) as! AppComponent)
}
private class MapSnippetDependency4bf09a63114e68842453Provider: MapSnippetDependency {
    var mapSnippetCache: any TrackMapSnippetCacheProtocol {
        return trackHistoryCellMockComponentProvider.mapSnippetCache
    }
    var mapSnapshotGenerator: any MapSnapshotGeneratorProtocol {
        return trackHistoryCellMockComponentProvider.mapSnapshotGenerator
    }
    private let trackHistoryCellMockComponentProvider: TrackHistoryCellMockComponentProvider
    init(trackHistoryCellMockComponentProvider: TrackHistoryCellMockComponentProvider) {
        self.trackHistoryCellMockComponentProvider = trackHistoryCellMockComponentProvider
    }
}
/// ^->TrackHistoryCellMockComponentProvider->TrackHistoryCellComponent->MapSnippetComponent
private func factory53a35471829210219a555df56f610f4d5e4f12ec(_ component: NeedleFoundation.Scope) -> AnyObject {
    return MapSnippetDependency4bf09a63114e68842453Provider(trackHistoryCellMockComponentProvider: parent2(component) as! TrackHistoryCellMockComponentProvider)
}
private class MapSnippetDependency1304440067d32f406655Provider: MapSnippetDependency {
    var mapSnippetCache: any TrackMapSnippetCacheProtocol {
        return mockMeasuredTrackDetailComponent.mapSnippetCache
    }
    var mapSnapshotGenerator: any MapSnapshotGeneratorProtocol {
        return mockMeasuredTrackDetailComponent.mapSnapshotGenerator
    }
    private let mockMeasuredTrackDetailComponent: MockMeasuredTrackDetailComponent
    init(mockMeasuredTrackDetailComponent: MockMeasuredTrackDetailComponent) {
        self.mockMeasuredTrackDetailComponent = mockMeasuredTrackDetailComponent
    }
}
/// ^->MockMeasuredTrackDetailComponent->MeasuredTrackDetailComponent->MapSnippetComponent
private func factory6081436e1e1e99cf7f9b36bfaaf810d08cc605e1(_ component: NeedleFoundation.Scope) -> AnyObject {
    return MapSnippetDependency1304440067d32f406655Provider(mockMeasuredTrackDetailComponent: parent2(component) as! MockMeasuredTrackDetailComponent)
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
        localTable["measuredTrackStorageService-any MeasuredTrackStorageProtocol"] = { [unowned self] in self.measuredTrackStorageService as Any }
        localTable["mapSnapshotGenerator-any MapSnapshotGeneratorProtocol"] = { [unowned self] in self.mapSnapshotGenerator as Any }
    }
}
extension RootComponent: NeedleFoundation.Registration {
    public func registerItems() {
        keyPathToName[\RootDependency.tabRouter] = "tabRouter-any TabRouterProtocol"
        keyPathToName[\RootDependency.routers] = "routers-[String: Router]"

    }
}
extension TrackPresetsComponent: NeedleFoundation.Registration {
    public func registerItems() {
        keyPathToName[\TrackPresetsDependency.measuredTrackStorageService] = "measuredTrackStorageService-any MeasuredTrackStorageProtocol"
    }
}
extension TracksTabComponent: NeedleFoundation.Registration {
    public func registerItems() {
        keyPathToName[\TracksTabDependency.storageService] = "storageService-any TrackStorageProtocol"
        keyPathToName[\TracksTabDependency.measuredTrackStorageService] = "measuredTrackStorageService-any MeasuredTrackStorageProtocol"
        keyPathToName[\TracksTabDependency.tabRouter] = "tabRouter-any TabRouterProtocol"
        keyPathToName[\TracksTabDependency.routers] = "routers-[String: Router]"
        keyPathToName[\TracksTabDependency.trackFileService] = "trackFileService-any TrackFileServiceProtocol"

    }
}
extension TrackHistoryCellComponent: NeedleFoundation.Registration {
    public func registerItems() {


    }
}
extension TrackHistoryCellMockComponentProvider: NeedleFoundation.Registration {
    public func registerItems() {

        localTable["mapSnippetCache-any TrackMapSnippetCacheProtocol"] = { [unowned self] in self.mapSnippetCache as Any }
        localTable["mapSnapshotGenerator-any MapSnapshotGeneratorProtocol"] = { [unowned self] in self.mapSnapshotGenerator as Any }
    }
}
extension TrackHistoryComponent: NeedleFoundation.Registration {
    public func registerItems() {
        keyPathToName[\TrackHistoryDependency.storageService] = "storageService-any TrackStorageProtocol"
        keyPathToName[\TrackHistoryDependency.tabRouter] = "tabRouter-any TabRouterProtocol"
        keyPathToName[\TrackHistoryDependency.routers] = "routers-[String: Router]"

    }
}
extension MeasuredTrackDetailComponent: NeedleFoundation.Registration {
    public func registerItems() {
        keyPathToName[\MeasuredTrackDetail.measuredTrackStorageService] = "measuredTrackStorageService-any MeasuredTrackStorageProtocol"
        keyPathToName[\MeasuredTrackDetail.tabRouter] = "tabRouter-any TabRouterProtocol"
        keyPathToName[\MeasuredTrackDetail.routers] = "routers-[String: Router]"

    }
}
extension MockMeasuredTrackDetailComponent: NeedleFoundation.Registration {
    public func registerItems() {

        localTable["locationService-any LocationServiceProtocol"] = { [unowned self] in self.locationService as Any }
        localTable["measuredTrackStorageService-any MeasuredTrackStorageProtocol"] = { [unowned self] in self.measuredTrackStorageService as Any }
        localTable["tabRouter-any TabRouterProtocol"] = { [unowned self] in self.tabRouter as Any }
        localTable["routers-[String: Router]"] = { [unowned self] in self.routers as Any }
        localTable["mapSnippetCache-any TrackMapSnippetCacheProtocol"] = { [unowned self] in self.mapSnippetCache as Any }
        localTable["mapSnapshotGenerator-any MapSnapshotGeneratorProtocol"] = { [unowned self] in self.mapSnapshotGenerator as Any }
    }
}
extension BaseMapComponent: NeedleFoundation.Registration {
    public func registerItems() {
        keyPathToName[\BaseMapDependency.trackReplayCoordinator] = "trackReplayCoordinator-any TrackReplayCoordinatorProtocol"
        keyPathToName[\BaseMapDependency.locationService] = "locationService-any LocationServiceProtocol"
        keyPathToName[\BaseMapDependency.storageService] = "storageService-any TrackStorageProtocol"
        keyPathToName[\BaseMapDependency.measuredTrackStorageService] = "measuredTrackStorageService-any MeasuredTrackStorageProtocol"

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
    registerProviderFactory("^->AppComponent->RootComponent->BaseMapComponent->TrackPresetsComponent", factoryc54fb74f56d2e8aeb21eb2702fa908b4cedb8464)
    registerProviderFactory("^->AppComponent->RootComponent->TracksTabComponent", factoryacee5c99c52fa1d62301b7304b634b3e62c64b3c)
    registerProviderFactory("^->AppComponent->RootComponent->TracksTabComponent->TrackHistoryCellComponent", factoryEmptyDependencyProvider)
    registerProviderFactory("^->TrackHistoryCellMockComponentProvider->TrackHistoryCellComponent", factoryEmptyDependencyProvider)
    registerProviderFactory("^->AppComponent->RootComponent->TracksTabComponent->TrackHistoryComponent->TrackHistoryCellComponent", factoryEmptyDependencyProvider)
    registerProviderFactory("^->TrackHistoryCellMockComponentProvider", factoryEmptyDependencyProvider)
    registerProviderFactory("^->AppComponent->RootComponent->TracksTabComponent->TrackHistoryComponent", factoryc63576fc92cbe40690f6b2702fa908b4cedb8464)
    registerProviderFactory("^->AppComponent->RootComponent->TracksTabComponent->MeasuredTrackDetailComponent", factorye99f29e6a1593ff65d10b2702fa908b4cedb8464)
    registerProviderFactory("^->MockMeasuredTrackDetailComponent->MeasuredTrackDetailComponent", factoryd2934ab103e0e67efe9f1ae3ea56d9e8d2e5cbf8)
    registerProviderFactory("^->MockMeasuredTrackDetailComponent", factoryEmptyDependencyProvider)
    registerProviderFactory("^->AppComponent->RootComponent->BaseMapComponent", factorybcfd2fbfb73eaddf911db7304b634b3e62c64b3c)
    registerProviderFactory("^->AppComponent->RootComponent->TracksTabComponent->MeasuredTrackDetailComponent->TrackMapComponent", factory75fb5090104e4103bd557586110118823dea9ff0)
    registerProviderFactory("^->AppComponent->RootComponent->TracksTabComponent->TrackDetailComponent->TrackMapComponent", factory75fb5090104e4103bd557586110118823dea9ff0)
    registerProviderFactory("^->AppComponent->RootComponent->TracksTabComponent->TrackHistoryComponent->TrackDetailComponent->TrackMapComponent", factory75fb5090104e4103bd559bb8c877c472a171438a)
    registerProviderFactory("^->MockMeasuredTrackDetailComponent->MeasuredTrackDetailComponent->TrackMapComponent", factorya6144c18161a70cca3b636bfaaf810d08cc605e1)
    registerProviderFactory("^->MockTrackMapDetailParentComponent->TrackMapComponent", factory6c4694b1def835eff0108adf4a46b14b88d9ed11)
    registerProviderFactory("^->MockTrackMapDetailParentComponent", factoryEmptyDependencyProvider)
    registerProviderFactory("^->AppComponent->RootComponent->TracksTabComponent->TrackDetailComponent", factory82bfc45ec1872278e5e2b2702fa908b4cedb8464)
    registerProviderFactory("^->AppComponent->RootComponent->TracksTabComponent->TrackHistoryComponent->TrackDetailComponent", factory82bfc45ec1872278e5e27586110118823dea9ff0)
    registerProviderFactory("^->AppComponent->RootComponent->TracksTabComponent->TrackHistoryCellComponent->MapSnippetComponent", factoryd7554d02d94d273d52197586110118823dea9ff0)
    registerProviderFactory("^->AppComponent->RootComponent->TracksTabComponent->TrackHistoryComponent->TrackHistoryCellComponent->MapSnippetComponent", factoryd7554d02d94d273d52199bb8c877c472a171438a)
    registerProviderFactory("^->AppComponent->RootComponent->TracksTabComponent->MeasuredTrackDetailComponent->MapSnippetComponent", factoryd7554d02d94d273d52197586110118823dea9ff0)
    registerProviderFactory("^->AppComponent->RootComponent->TracksTabComponent->TrackDetailComponent->MapSnippetComponent", factoryd7554d02d94d273d52197586110118823dea9ff0)
    registerProviderFactory("^->AppComponent->RootComponent->TracksTabComponent->TrackHistoryComponent->TrackDetailComponent->MapSnippetComponent", factoryd7554d02d94d273d52199bb8c877c472a171438a)
    registerProviderFactory("^->TrackHistoryCellMockComponentProvider->TrackHistoryCellComponent->MapSnippetComponent", factory53a35471829210219a555df56f610f4d5e4f12ec)
    registerProviderFactory("^->MockMeasuredTrackDetailComponent->MeasuredTrackDetailComponent->MapSnippetComponent", factory6081436e1e1e99cf7f9b36bfaaf810d08cc605e1)
    registerProviderFactory("^->MockMapSnippetParentComponent->MapSnippetComponent", factory8866217649a5eb73d4929ff55ac03fada00284bc)
    registerProviderFactory("^->MockMapSnippetParentComponent", factoryEmptyDependencyProvider)
}
#endif

public func registerProviderFactories() {
#if !NEEDLE_DYNAMIC
    register1()
#endif
}
