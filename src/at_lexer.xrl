%% SPDX-FileCopyrightText: 2020 Frank Hunleth
%%
%% SPDX-License-Identifier: Apache-2.0
%%
Definitions.

INTEGER    = [0-9]+
HEX        = 0x[A-Fa-f0-9]+
STRING     = \"[^\"]*\"
HEADER     = \+[A-Z]+:\s

Rules.

{INTEGER}     : {token, list_to_integer(TokenChars)}.
{HEX}         : {token, list_to_integer(tl(tl(TokenChars)), 16)}.
{STRING}      : {token, list_to_binary(trim_quotes(TokenChars))}.
{HEADER}      : {token, {header, list_to_binary(TokenChars)}}.
,             : skip_token.

Erlang code.

trim_quotes(Input) ->
    lists:droplast(tl(Input)).
