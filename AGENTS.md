The BDFL is not too precious about the actual bash code in here, it's obviously a horror fest already by dint of being 10k lines of human authored bash, instead of *literally any other better language*. That said,

DO NOT author GitHub Issues for the human.
DO NOT write PR descriptions for the human.
DO NOT write code comments for the human, nor the markdown documentation stored in the `handle_help` sections.
DO NOT write any error messages that might be shown to the end user. Ask the user to fill them out in their own words or leave a "TODO".

All of those portions MUST ALWAYS BE HUMAN AUTHORED.

It is fully asocial to communicate with another person through a game of probabalistic sampling. the BDFL is not interested in playing the [telephone game](https://en.wikipedia.org/wiki/Telephone_game) with the worst people on earth's computational abomination in between us.

The human must be able to understand and explain their contribution and rationale.

All contributions should be kept according to the existing style of code that is in the codebase.

Here we take inspiration from the rust LLM policy:

- ✅ Allowed: Private use.
- ❌ Banned: LLM-created comments, docs, or diagnostics. Replacing human judgement with LLM judgement. Requiring people to use an LLM to contribute.
- ⚠️ Conditionally allowed: Trivial changes, machine translation, LLM reviews and review bots, LLM authored code provided it is the minimal implementation of the desired changes.
- 🔨 Carries a moderation penalty: Lying.
- Using an LLM for your own personal use is likely allowed ✅
- Showing LLM output to another human without solicitation is likely banned ❌
- Making a decision that affects others based on LLM output requires disclosure ⚠️
