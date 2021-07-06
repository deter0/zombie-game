
function partition(array, left, right, pivotIndex, index)
	local pivotValue = array[pivotIndex][index];
	array, array[right] = array[right], array[pivotIndex];
	
	local storeIndex = left
	
	for i =  left, right-1 do
    	if array[i][index] <= pivotValue then
	        array[i], array[storeIndex] = array[storeIndex], array[i]
	        storeIndex = storeIndex + 1
		end
		array[storeIndex], array[right] = array[right], array[storeIndex]
	end
	
   return storeIndex
end

function quicksort(array, left, right, index)
	if right > left then
	    local pivotNewIndex = partition(array, left, right, left)
	    quicksort(array, left, pivotNewIndex - 1, index)
	    quicksort(array, pivotNewIndex + 1, right, index)
	end
end

return quicksort;