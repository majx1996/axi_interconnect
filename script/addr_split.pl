#!/usr/bin/perl

use Getopt::Long;

$init = "0x50002000";
$end  = "0x5000FFFF";

GetOptions(
    'i|init=s' => \$init,
    'e|end=s' => \$end,
);

@addr_arr = &addr_split($init, $end);
$arr_len = @addr_arr;

for($i=0;$i<=$arr_len-1;$i+=2){
    print "$addr_arr[$i], $addr_arr[$i+1]\n";
}

sub addr_split{
    $init = $_[0];
    $end = $_[1];

    if($init =~ /0x([0-9a-f]+)/i){
        $init = hex($1);
    }
    if($end =~ /0x([0-9a-f]+)/i){
        $end = hex($1);
    }
    
    $diff = $end - $init;
    
    unless(($diff >= 4095) && (($diff % 4096) == 4095)) {
        die "Error, do not conform to the 4K\n";
    }
    
    do {
        $diff = $end - $init;
        $diff_bin = sprintf("%b", $diff);
        $diff_bin_len = length($diff_bin);
    
        $all_one = 2**$diff_bin_len - 1;
        $all_one_bin = sprintf("%b", $all_one);
    
        if(($diff ^ $all_one) == 0){
            $continue_flag = 0;
        }else{
            $continue_flag = 1;
        }
     
        if($continue_flag == 0){
            $end_tmp = $init + $diff;
        }else{
            for($cnt = 0; ((($diff >> $cnt) & 1) == 1); $cnt += 1){
            }
            $end_tmp = $init + (2**$cnt) -1;
        }
        
        $init_hex = sprintf("%8X", $init);
        $endtmp_hex = sprintf("%8X", $end_tmp);

        push @return_arr, ($init_hex, $endtmp_hex);

        $init = $end_tmp + 1;
    
    }while($continue_flag == 1);

    return @return_arr;
}
