#include <bits/stdc++.h>
using namespace std;

// ---------- Data structures ----------
// transition rule for the Turing machine
struct Rule {
    char write;
    char move;     // 'L', 'R', 'S'
    string next;
};
// δ(q, read) → (write, move, q')

struct TM {
    unordered_set<string> states; // Q: set of states
    unordered_set<char> inputAlphabet; // Σ: input alphabet
    unordered_set<char> tapeAlphabet; // Γ: tape alphabet
    char blank = '_'; // blank symbol
    string start, accept, reject; // q0, qaccept, qreject
    unordered_map<string, unordered_map<char, Rule>> delta; // δ transition function
    // gives rule for state symbol pair
    // ex: delta["q0"]['a'] = Rule{'b','R',"q1"};

    // Runtime
    string state;
    long long head = 0;
    long long steps = 0;
    optional<tuple<string,char,char,char,string>> lastRule; // q,read,write,move,q'
    unordered_map<long long,char> tape; // sparse

    void reset(const string& input) {
        state = start;
        head = 0;
        steps = 0;
        lastRule.reset();
        tape.clear();
        for (size_t i=0;i<input.size();++i) {
            char c = input[i];
            if (!tapeAlphabet.count(c)) throw runtime_error("Input symbol not in tape alphabet: "s + c);
            tape[(long long)i] = c;
        }
    }

    char readCell(long long i) {
        auto it = tape.find(i);
        if (it==tape.end()) return blank;
        return it->second;
    }

    bool stepOnce() {
        if (state == accept || state == reject) return false;
        char sym = readCell(head);
        auto sit = delta.find(state);
        if (sit==delta.end() || sit->second.find(sym)==sit->second.end()) {
            // implicit reject on missing transition
            lastRule = tuple(state, sym, (char)0, (char)0, reject);
            state = reject;
            return false;
        }
        Rule r = sit->second[sym];
        // write
        tape[head] = r.write;
        // move
        if (r.move=='L') head--;
        else if (r.move=='R') head++;
        else if (r.move=='S') {}
        else throw runtime_error("Bad move: "s + r.move);
        // next
        lastRule = tuple(state, sym, r.write, r.move, r.next);
        state = r.next;
        steps++;
        return true;
    }

    // Run until halt or stepCap
    pair<bool,string> run(long long stepCap) {
        while (steps < stepCap && stepOnce()) {}
        if (state == accept) return {true, "Accepted"};
        if (state == reject) return {true, "Rejected"};
        return {false, "Step cap reached (possible non-halting)"};
    }

    // Pretty print window around head
    string pretty(int halfWindow=15) {
        long long left = head - halfWindow;
        long long right = head + halfWindow;
        // make sure we render any non-blank cells just outside window if present
        for (auto &p: tape) {
            if (p.first < left) left = min(left, p.first);
            if (p.first > right) right = max(right, p.first);
        }
        // clamp window size to something reasonable
        if (right - left > 120) {
            left = head - halfWindow;
            right = head + halfWindow;
        }
        // tape line
        string line, caret;
        for (long long i=left;i<=right;++i) {
            char c = readCell(i);
            line.push_back(c);
            line.push_back(' ');
            caret.push_back(i==head ? '^' : ' ');
            caret.push_back(' ');
        }
        string info = "state=" + state + " steps=" + to_string(steps);
        if (lastRule.has_value() && get<2>(*lastRule)!=0) {
            auto [q,r,w,m,qn] = *lastRule;
            info += " last: δ(" + q + "," + string(1,r) + ")->(" +
                    string(1,w) + "," + string(1,m) + "," + qn + ")";
        }
        return line + "\n" + caret + "\n" + info;
    }
};

// ---------- Helpers ----------
static inline string trim(const string& s) {
    size_t a = s.find_first_not_of(" \t\r\n");
    size_t b = s.find_last_not_of(" \t\r\n");
    if (a==string::npos) return "";
    return s.substr(a, b-a+1);
}

vector<string> splitCSV(const string& s) {
    vector<string> out;
    string cur;
    for (char c: s) {
        if (c==',') {
            out.push_back(trim(cur));
            cur.clear();
        } else cur.push_back(c);
    }
    if (!cur.empty()) out.push_back(trim(cur));
    vector<string> out2;
    for (auto &x: out) if (!x.empty()) out2.push_back(x);
    return out2;
}

bool startsWith(const string& s, const string& pfx) {
    return s.rfind(pfx, 0) == 0;
}

// ---------- Parser for simple .tm format ----------
TM parseTMFile(istream& in) {
    TM tm;
    bool inDelta = false;
    string line;
    while (getline(in, line)) {
        line = trim(line);
        if (line.empty() || line[0]=='#') continue;
        if (!inDelta) {
            if (startsWith(line, "states:")) {
                auto v = splitCSV(trim(line.substr(7)));
                for (auto &q: v) if(!q.empty()) tm.states.insert(q);
            } else if (startsWith(line, "start:")) {
                tm.start = trim(line.substr(6));
            } else if (startsWith(line, "accept:")) {
                tm.accept = trim(line.substr(7));
            } else if (startsWith(line, "reject:")) {
                tm.reject = trim(line.substr(7));
            } else if (startsWith(line, "blank:")) {
                string b = trim(line.substr(6));
                if (b.size()!=1) throw runtime_error("blank must be 1 char");
                tm.blank = b[0];
            } else if (startsWith(line, "input_alphabet:")) {
                auto v = splitCSV(trim(line.substr(15)));
                for (auto &s: v) if (!s.empty()) tm.inputAlphabet.insert(s[0]);
            } else if (startsWith(line, "tape_alphabet:")) {
                auto v = splitCSV(trim(line.substr(14)));
                for (auto &s: v) if (!s.empty()) tm.tapeAlphabet.insert(s[0]);
            } else if (startsWith(line, "delta:")) {
                inDelta = true;
            } else {
                throw runtime_error("Unknown header line: " + line);
            }
        } else {
            // transition: q read -> write move next
            vector<string> tok;
            string cur;
            for (size_t i=0;i<line.size();++i) {
                char c = line[i];
                if (isspace((unsigned char)c)) {
                    if (!cur.empty()) { tok.push_back(cur); cur.clear(); }
                } else {
                    cur.push_back(c);
                }
            }
            if (!cur.empty()) tok.push_back(cur);
            if (tok.size()!=6 || tok[2]!="->")
                throw runtime_error("Bad transition line: " + line);
            string q = tok[0];
            if (tok[1].size()!=1) throw runtime_error("READ must be 1 char");
            char read = tok[1][0];
            if (tok[3].size()!=1) throw runtime_error("WRITE must be 1 char");
            char write = tok[3][0];
            if (tok[4].size()!=1) throw runtime_error("MOVE must be 1 char");
            char move = tok[4][0];
            string next = tok[5];
            tm.delta[q][read] = Rule{write, move, next};
        }
    }
    if (tm.tapeAlphabet.empty()) {
        for (auto &p: tm.delta) for (auto &q: p.second) tm.tapeAlphabet.insert(q.first);
        tm.tapeAlphabet.insert(tm.blank);
    }
    if (tm.inputAlphabet.empty()) {
        for (char c: tm.tapeAlphabet) if (c!=tm.blank) tm.inputAlphabet.insert(c);
    }
    if (tm.states.empty() || tm.start.empty() || tm.accept.empty() || tm.reject.empty())
        throw runtime_error("Missing one of: states/start/accept/reject");
    return tm;
}

// ---------- Built-in examples ----------
TM builtin_binary_incrementer() {
    string spec = R"(states: q0,qScan,qCarry,qDone,qacc,qrej
start: q0
accept: qacc
reject: qrej
blank: _
input_alphabet: 0,1
tape_alphabet: 0,1,_
delta:
q0 0 -> 0 R qScan
q0 1 -> 1 R qScan
q0 _ -> 1 S qacc
qScan 0 -> 0 R qScan
qScan 1 -> 1 R qScan
qScan _ -> _ L qCarry
qCarry 1 -> 0 L qCarry
qCarry 0 -> 1 S qDone
qCarry _ -> 1 S qDone
qDone 0 -> 0 S qacc
qDone 1 -> 1 S qacc
qDone _ -> _ S qacc
)";
    stringstream ss(spec);
    return parseTMFile(ss);
}

TM builtin_palindrome_ab_hash() {
    string spec = R"(states: q0,qSeekRightA,qSeekRightB,qMarkLeftA,qMarkLeftB,qBack,qCheckDone,qacc,qrej
start: q0
accept: qacc
reject: qrej
blank: _
input_alphabet: a,b,#
tape_alphabet: a,b,#,A,B,x,_
delta:
q0 a -> x R qSeekRightA
q0 b -> x R qSeekRightB
q0 # -> # R qCheckDone
q0 x -> x R q0
q0 A -> A R q0
q0 B -> B R q0
q0 _ -> _ S qrej
qSeekRightA a -> a R qSeekRightA
qSeekRightA b -> b R qSeekRightA
qSeekRightA x -> x R qSeekRightA
qSeekRightA # -> # R qSeekRightA
qSeekRightA A -> A R qSeekRightA
qSeekRightA B -> B R qSeekRightA
qSeekRightA _ -> _ L qMarkLeftA
qSeekRightB a -> a R qSeekRightB
qSeekRightB b -> b R qSeekRightB
qSeekRightB x -> x R qSeekRightB
qSeekRightB # -> # R qSeekRightB
qSeekRightB A -> A R qSeekRightB
qSeekRightB B -> B R qSeekRightB
qSeekRightB _ -> _ L qMarkLeftB
qMarkLeftA A -> A L qMarkLeftA
qMarkLeftA B -> B L qMarkLeftA
qMarkLeftA a -> A L qBack
qMarkLeftA b -> b S qrej
qMarkLeftA # -> # L qMarkLeftA
qMarkLeftA x -> x L qMarkLeftA
qMarkLeftB A -> A L qMarkLeftB
qMarkLeftB B -> B L qMarkLeftB
qMarkLeftB b -> B L qBack
qMarkLeftB a -> a S qrej
qMarkLeftB # -> # L qMarkLeftB
qMarkLeftB x -> x L qMarkLeftB
qBack a -> a L qBack
qBack b -> b L qBack
qBack A -> A L qBack
qBack B -> B L qBack
qBack x -> x L qBack
qBack # -> # L qBack
qBack _ -> _ R q0
qCheckDone A -> A R qCheckDone
qCheckDone B -> B R qCheckDone
qCheckDone x -> x R qCheckDone
qCheckDone _ -> _ S qacc
qCheckDone a -> a S qrej
qCheckDone b -> b S qrej
qCheckDone # -> # R qCheckDone
)";
    stringstream ss(spec);
    return parseTMFile(ss);
}

TM builtin_anbn() {
    string spec = R"(states: q0,qSeekB,qBack,qCheckDone,qacc,qrej
start: q0
accept: qacc
reject: qrej
blank: _
input_alphabet: a,b
tape_alphabet: a,b,X,Y,_
delta:
q0 a -> X R qSeekB
q0 b -> b S qrej
q0 X -> X R q0
q0 Y -> Y R q0
q0 _ -> _ S qCheckDone
qSeekB a -> a R qSeekB
qSeekB X -> X R qSeekB
qSeekB Y -> Y R qSeekB
qSeekB b -> Y L qBack
qSeekB _ -> _ S qrej
qBack a -> a L qBack
qBack b -> b L qBack
qBack X -> X L qBack
qBack Y -> Y L qBack
qBack _ -> _ R q0
qCheckDone Y -> Y R qCheckDone
qCheckDone X -> X R qCheckDone
qCheckDone _ -> _ S qacc
qCheckDone a -> a S qrej
qCheckDone b -> b S qrej
)";
    stringstream ss(spec);
    return parseTMFile(ss);
}

TM builtin_unary_add() {
    string spec = R"(states: q0,qScanRight,qAppend,qacc,qrej
start: q0
accept: qacc
reject: qrej
blank: _
input_alphabet: 1,0
tape_alphabet: 1,0,_
delta:
q0 1 -> 1 R q0
q0 0 -> 0 R qScanRight
q0 _ -> _ S qrej
qScanRight 1 -> _ L qAppend
qScanRight _ -> _ L qAppend
qScanRight 0 -> 0 R qScanRight
qAppend 1 -> 1 L qAppend
qAppend 0 -> 0 L qAppend
qAppend _ -> 1 S qacc
)";
    stringstream ss(spec);
    return parseTMFile(ss);
}

TM builtin_non_halting_right() {
    string spec = R"(states: q0,qrej
start: q0
accept: qrej
reject: qrej
blank: _
input_alphabet: 0,1
tape_alphabet: 0,1,_
delta:
q0 0 -> 0 R q0
q0 1 -> 1 R q0
q0 _ -> _ R q0
)";
    stringstream ss(spec);
    return parseTMFile(ss);
}

// ---------- CLI ----------
struct Args {
    string example;
    string file;
    string input;
    bool run=false;
    bool step=false;
    long long maxSteps=2000;
    int window=15;
};

Args parseArgs(int argc, char** argv) {
    Args a;
    for (int i=1;i<argc;i++) {
        string s = argv[i];
        auto need = [&](int i){ if (i+1>=argc) throw runtime_error("Missing value for "+s); };
        if (s=="--example") { need(i); a.example = argv[++i]; }
        else if (s=="--file") { need(i); a.file = argv[++i]; }
        else if (s=="--input") { need(i); a.input = argv[++i]; }
        else if (s=="--run") { a.run = true; }
        else if (s=="--step") { a.step = true; }
        else if (s=="--max-steps") { need(i); a.maxSteps = stoll(argv[++i]); }
        else if (s=="--window") { need(i); a.window = stoi(argv[++i]); }
        else if (s=="--help" || s=="-h") {
            cout <<
"Usage: ./tm [--example NAME | --file PATH] [--input STR] [--run | --step]\n"
"             [--max-steps N] [--window K]\n\n"
"Built-ins: binary_incrementer, palindrome_ab_hash, anbn, unary_add, non_halting_right\n";
            exit(0);
        } else {
            throw runtime_error("Unknown argument: " + s);
        }
    }
    return a;
}

int main(int argc, char** argv) {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    try {
        Args args = parseArgs(argc, argv);

        TM tm;
        if (!args.example.empty()) {
            string e = args.example;
            if (e=="binary_incrementer") tm = builtin_binary_incrementer();
            else if (e=="palindrome_ab_hash") tm = builtin_palindrome_ab_hash();
            else if (e=="anbn") tm = builtin_anbn();
            else if (e=="unary_add") tm = builtin_unary_add();
            else if (e=="non_halting_right") tm = builtin_non_halting_right();
            else {
                cerr << "Unknown example: " << e << "\n";
                return 1;
            }
        } else if (!args.file.empty()) {
            ifstream fin(args.file);
            if (!fin) { cerr << "Cannot open file: " << args.file << "\n"; return 1; }
            tm = parseTMFile(fin);
        } else {
            cerr << "Provide --example NAME or --file PATH (use --help).\n";
            return 1;
        }

        //load tape
        tm.reset(args.input);

        auto show = [&](){
            cout << tm.pretty(args.window) << "\n";
        };

        if (args.run) {
            show();
            auto [halted, reason] = tm.run(args.maxSteps);
            show();
            cout << "\nResult: halted=" << (halted?"true":"false")
                 << " accepted=" << (tm.state==tm.accept?"true":"false")
                 << " steps=" << tm.steps
                 << " reason=" << reason << "\n";
            return 0;
        }

        // Default: step mode
        cout << "Interactive step mode. Enter=step, 'r'=run to cap, 'q'=quit.\n\n";
        show();
        string line;
        while (true) {
            cout << "> " << flush;
            if (!getline(cin, line)) break;
            string cmd; for (auto c: line) if (!isspace((unsigned char)c)) cmd.push_back(tolower(c));
            if (cmd=="q") break;
            if (cmd=="r") {
                auto [halted, reason] = tm.run(args.maxSteps);
                show();
                cout << "\nResult: halted=" << (halted?"true":"false")
                     << " accepted=" << (tm.state==tm.accept?"true":"false")
                     << " steps=" << tm.steps
                     << " reason=" << reason << "\n";
                break;
            }
            bool progressed = tm.stepOnce();
            show();
            if (!progressed) {
                bool halted = (tm.state==tm.accept || tm.state==tm.reject);
                cout << "\nHalted=" << (halted?"true":"false")
                     << " in state=" << tm.state
                     << " after " << tm.steps << " steps.\n";
                break;
            }
        }
    } catch (const exception& e) {
        cerr << "Error: " << e.what() << "\n";
        return 1;
    }
    return 0;
}
