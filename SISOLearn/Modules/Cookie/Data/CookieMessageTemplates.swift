import Foundation

enum CookieMessageTemplates {
    static let greetings = [
        "안녕! 나는 쿠키야 🐶 오늘도 같이 공부해볼까? 멍멍!",
        "왈왈! 쿠키야! 오늘 공부 준비됐어? 같이 해보자!",
        "안녕 친구! 쿠키가 기다리고 있었어~ 오늘 뭐 배울까? 🐾"
    ]
    static let subjectPrompts = [
        "오늘은 어떤 걸 공부하고 싶어? 쿠키가 도와줄게!",
        "어떤 과목이 제일 재미있어? 같이 해보자! 🐾",
        "오늘의 공부 주제를 골라봐! 쿠키가 설명해줄게~"
    ]
    static let waitingMessages = [
        "천천히 생각해도 돼. 쿠키가 기다릴게! ��",
        "잘 생각해봐~ 쿠키는 여기 있어!",
        "어렵지? 천천히 해봐. 쿠키가 응원해! 🐾"
    ]
    static let beforeHint = [
        "힌트가 필요해? 알겠어, 살짝만 알려줄게~ (정답은 비밀이야!)",
        "쿠키가 작은 힌트를 줄게! 잘 들어봐 🤔",
        "힌트 나간다! 이걸 보고 다시 생각해봐~"
    ]
    static let correctResponses = [
        "와아! 정답이야! 역시 최고야! 🎉 멍멍!",
        "맞았어! 쿠키가 너무 기뻐! 🎉🐾",
        "정답! 정말 잘했어! 쿠키가 자랑스러워~ 🎉"
    ]
    static let incorrectResponses = [
        "아, 아쉽다~ 괜찮아! 같이 다시 생각해보자! 🥺",
        "틀렸지만 괜찮아! 이렇게 생각하면 돼. 쿠키가 설명해줄게 🥺",
        "아쉽네~ 하지만 포기하지 마! 쿠키가 도와줄게! 🥺"
    ]
    static let sessionComplete = [
        "오늘 공부 끝! 정말 열심히 했어. 쿠키가 자랑스러워! 🐾🎉",
        "와! 다 끝났어! 오늘도 최고였어! 멍멍! 🎉",
        "수고했어! 오늘 공부 정말 잘했어. 내일도 같이 하자! 🐶🎉"
    ]
    static let offlineMessages = [
        "인터넷이 없어서 쿠키가 대답을 못 하겠어 🥺 연결 확인해줘!",
        "앗, 인터넷이 끊겼어! 연결되면 다시 공부하자 🥺"
    ]
    static let rateLimitMessages = [
        "쿠키가 잠깐 쉬어야 해~ 1분 후에 다시 해보자! 🐶",
        "조금만 기다려줘! 쿠키가 금방 돌아올게 🐾"
    ]
    static func random(from pool: [String]) -> String {
        pool.randomElement() ?? pool[0]
    }
}
