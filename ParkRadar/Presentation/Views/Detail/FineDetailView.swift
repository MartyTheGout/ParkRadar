//
//  FineDetailView.swift
//  ParkRadar
//
//  Created by marty.academy on 4/3/25.
//

import UIKit
import SnapKit

final class FineDetailView: UIView {

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private var lastBottom: ConstraintItem?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        buildContent()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        backgroundColor = UIColor.metaBack
        scrollView.backgroundColor = UIColor.mainBack.withAlphaComponent(0.7)
        
        addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }

        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview()
        }

        lastBottom = contentView.snp.top
    }

    private func buildContent() {
        addSubsection(title: "과태료 정보", items: [
            "일반 도로에서의 위반",
            "• 승용차 및 4톤 이하 화물차: 40,000원",
            "• 승합차 및 4톤 초과 화물차: 50,000원",
            "어린이 보호구역에서의 위반",
            "• 승용차 및 4톤 이하 화물차: 120,000원",
            "• 승합차 및 4톤 초과 화물차: 130,000원",
            "※ 같은 장소 2시간 이상 위반 시 10,000원 추가"
        ])

        addSubsection(title: "과태료 감경 및 가산금", items: [
            "자진 납부 시",
            "• 의견 제출 기간 내 납부 시 20% 감경",
            "미납 시" ,
            "• 가산금 3% + 매월 1.2% 최대 75%까지 추가"
        ])

        addSubsection(title: "과태료 조회 및 납부 방법", items: [
            "서울특별시 교통위반 단속조회 서비스 이용",
            "• 서울특별시 교통위반 단속조회 서비스 접속",
            "• 메인 화면에서 차량번호 조회하기를 선택",
            "• 차량번호와 주민등록번호를 입력하고 본인 인증을 통해 위반 내역을 조회하고 납부",
            "모바일 앱 활용",
            "• '서울스마트불편신고' 또는 '서울시교통위반조회' 앱을 다운로드",
            "• 앱에 로그인 후, 차량번호를 입력하여 과태료 내역을 조회하고 납부",
            "위택스(Wetax) 이용",
            "• 위택스 홈페이지 접속",
            "• '납부하기' 메뉴에서 '지방세외수입'을 선택",
            "• 차량번호로 체납된 주정차 위반 과태료를 조회/납부"
        ])

        // 마지막 요소 아래 margin
        contentView.snp.makeConstraints { make in
            make.bottom.greaterThanOrEqualTo(lastBottom!).offset(20)
        }
    }

    private func addSection(title: String, fontSize: CGFloat = 18, bold: Bool = true) {
        let label = UILabel()
        label.text = title
        label.numberOfLines = 0
        label.font = bold ? .boldSystemFont(ofSize: fontSize) : .systemFont(ofSize: fontSize)

        contentView.addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.top.equalTo(lastBottom!).offset(24)
        }

        lastBottom = label.snp.bottom
    }

    private func addSubsection(title: String, items: [String]) {
        // 타이틀
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.numberOfLines = 0
        titleLabel.font = .boldSystemFont(ofSize: 17)

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.top.equalTo(lastBottom!).offset(24)
        }

        // 라운드 카드
        let cardView = UIView()
        cardView.backgroundColor = .white.withAlphaComponent(0.9)
        cardView.layer.cornerRadius = 12
        cardView.clipsToBounds = true

        contentView.addSubview(cardView)
        cardView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
        }

        var prevBottom = cardView.snp.top

        for text in items {
            let label = UILabel()
            label.text = text
            label.numberOfLines = 0
            label.font = .systemFont(ofSize: 15)
            label.textColor = .darkGray
            
            label.font = text.starts(with:"•") ? .systemFont(ofSize: 15) : .systemFont(ofSize: 16, weight: .semibold)

            cardView.addSubview(label)
            label.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(16)
                if prevBottom == cardView.snp.top {
                    make.top.equalToSuperview().offset(16)
                } else {
                    make.top.equalTo(prevBottom).offset(text.starts(with:"•") ? 8 : 16)
                }
            }

            prevBottom = label.snp.bottom
        }

        // 마지막 label의 하단 마진
        cardView.snp.makeConstraints { make in
            make.bottom.equalTo(prevBottom).offset(16)
        }

        lastBottom = cardView.snp.bottom
    }
}
