# https://en.wikibooks.org/wiki/Algorithm_Implementation/Strings/Levenshtein_distance
levenshtein='
function levenshtein(str1, str2, cost_ins, cost_rep, cost_del,    str1_len, str2_len, matrix, is_match, i, j, x, y, z) {
	if(cost_ins == "") cost_ins = 1
	if(cost_rep == "") cost_rep = 1
	if(cost_del == "") cost_del = 1
	str1_len = length(str1)
	str2_len = length(str2)
	if(str1_len == 0) return str2_len * cost_ins
	if(str2_len == 0) return str1_len * cost_del
	matrix[0, 0] = 0
	for(i = 1; i <= str1_len; i++) {
		matrix[i, 0] = i * cost_del
		for(j = 1; j <= str2_len; j++) {
			matrix[0, j] = j * cost_ins
			x = matrix[i - 1, j] + cost_del
			y = matrix[i, j - 1] + cost_ins
			z = matrix[i - 1, j - 1] + (substr(str1, i, 1) == substr(str2, j, 1) ? 0 : cost_rep)
			x = x < y ? x : y
			matrix[i, j] = x < z ? x : z
		}
	}
	return matrix[str1_len, str2_len]
}
{
	print levenshtein($1, $2)"\t"$1;
}'


levenshtein_filter(){
	cat | awk -f <(echo "$levenshtein") | sort -nk1 | head -n 10
}
