namespace eval ::RegExp {
    namespace export ere-build*

    proc ere-build-case-insensetive-word {word} {
        set chars [split $word {}]
        set ere_word {}
        foreach c $chars {
            set ere_word "$ere_word\[[string toupper $c][string tolower $c]\]"
        }
        return $ere_word
    }
}