function ceil(valor) {
	return (valor == int(valor)) ? valor : int(valor)+1;
}
function rice_rule(n){
	return ceil(2 * (n ** 0.33333));
}
BEGIN {
	# Idk;
	min_n=1000000000000000000;
	max=-1000000000000000000;
}

# MAIN
{
	n=$1;
	a[n]++;
	# For the max bin width
	#if (a[n]>max) max=a[n]

	# For the max/min values
	if (n>max_n){max_n=n;}
	if (n<min_n){min_n=n;}
	k++;
}

END {
	bins=rice_rule(k);
	diff=max_n - min_n;
	bin_width=(diff / bins);
	# printf("Debug max=%s\tmin=%s\tn=%s\tk(rice)=%s\tdiff=%s\tbin_width=%s\n", max_n, min_n, k, bins, diff, bin_width);
	for (i=0; i<=bins; i++){
		ls=min_n + (i * bin_width) + 0.0;
		rs=min_n + ((i + 1) * bin_width) + 0.0;
		# printf("bin=%s ls=%s rs=%s bw=%s\n", i, ls, rs, bin_width);
		for(j in a){
			if((j + 0.0) >= ls && (j + 0.0) < rs){
				b2[i] += a[j];
				# printf("\tj=%s j >= %s && j < %s, a[j]=%s => b2[i]=%s\n", j, ls, rs, a[j], b2[i]);
				if(b2[i] > max){max=b2[i];}
			}
		}
	}

	for (i=0; i<=bins; i++){
		ls = min_n + (i * bin_width);
		rs = min_n + ((i + 1) * bin_width);

		lsf = sprintf("%0.3f", ls);
		rsf = sprintf("%0.3f", rs);

		if(i == 0){
			printf("(%8s, %8s) ", lsf, rsf);
		} else {
			printf("[%8s, %8s) ", lsf, rsf);
		}
		printf("n=%-5d ", b2[i]);
		for (j=0;j<(int(b2[i]*(50/max)));j++){printf("*");}
		printf("\n");
	}
}
