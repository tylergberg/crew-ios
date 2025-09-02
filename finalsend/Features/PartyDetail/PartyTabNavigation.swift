//
//  PartyTabNavigation.swift
//  finalsend
//
//  Created by Tyler Greenberg on 2025-07-30.
//

import SwiftUI

typealias PartyDetailTabType = PartyDetailTab

struct PartyTabNavigation: View {
    @Binding var selectedTab: PartyDetailTabType
    let visibleTabs: [PartyDetailTabType]
    @State private var scrollViewProxy: ScrollViewProxy? = nil
    @State private var scrollOffset: CGFloat = 0
    @State private var contentWidth: CGFloat = 0
    @State private var scrollViewWidth: CGFloat = 0

    let scrollStep: CGFloat = 100

    var contentOverflows: Bool {
        contentWidth > scrollViewWidth
    }

    var showLeftArrow: Bool {
        contentOverflows
    }

    var showRightArrow: Bool {
        contentOverflows
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                HStack(spacing: 0) {
                    Button(action: {
                        scrollLeft()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 36, height: 36)
                            .background(Color(hex: "#F9C94E"))
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.black, lineWidth: 2)
                            )
                            .foregroundColor(Color(hex: "#401B17"))
                    }
                    .disabled(!showLeftArrow)
                    .padding(.leading, 4)

                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(visibleTabs, id: \.self) { tab in
                                    tabButton(for: tab)
                                }
                            }
                            .background(
                                GeometryReader { geo in
                                    Color.clear
                                        .onAppear {
                                            contentWidth = geo.size.width
                                        }
                                        .onChange(of: geo.size.width) { newValue in
                                            contentWidth = newValue
                                        }
                                }
                            )
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                        }
                        .onAppear {
                            scrollViewProxy = proxy
                            scrollViewWidth = geometry.size.width - 88 // 44 for each arrow + padding
                        }
                        .onChange(of: geometry.size.width) { newWidth in
                            scrollViewWidth = newWidth - 88
                        }
                        .onChange(of: selectedTab) { newValue in
                            withAnimation {
                                proxy.scrollTo(newValue.rawValue, anchor: .center)
                            }
                        }
                    }
                    .frame(height: 60)

                    Button(action: {
                        scrollRight()
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 36, height: 36)
                            .background(Color(hex: "#F9C94E"))
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.black, lineWidth: 2)
                            )
                            .foregroundColor(Color(hex: "#401B17"))
                    }
                    .disabled(!showRightArrow)
                    .padding(.trailing, 4)
                }
            }
            .background(Color(hex: "#9BC8EE"))
        }
        .frame(height: 60)
    }

    private func tabButton(for tab: PartyDetailTabType) -> some View {
        Button(action: {
            selectedTab = tab
        }) {
            Image(systemName: tab.iconName)
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 52, height: 36)
                .background(selectedTab == tab ? Color(hex: "#F9C94E") : Color(hex: "#FDF3E7"))
                .foregroundColor(Color(hex: "#401B17"))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black, lineWidth: 2)
                )
                .cornerRadius(12)
                .shadow(color: selectedTab == tab ? Color.black.opacity(0.2) : Color.black.opacity(0.6), radius: 2, x: 2, y: 2)
        }
        .id(tab.rawValue)
    }

    private func scrollLeft() {
        guard let proxy = scrollViewProxy else { return }
        let newOffset = max(scrollOffset - scrollStep, 0)
        scrollToOffset(newOffset)
    }

    private func scrollRight() {
        guard let proxy = scrollViewProxy else { return }
        let maxOffset = max(contentWidth - scrollViewWidth, 0)
        let newOffset = min(scrollOffset + scrollStep, maxOffset)
        scrollToOffset(newOffset)
    }

    private func scrollToOffset(_ offset: CGFloat) {
        scrollOffset = offset
        if visibleTabs.isEmpty { return }
        let tabWidth: CGFloat = 52
        let index = min(max(Int(offset / tabWidth), 0), visibleTabs.count - 1)
        withAnimation {
            scrollViewProxy?.scrollTo(visibleTabs[index].rawValue, anchor: .leading)
        }
    }
}
