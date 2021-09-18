String getInitialCharFromWords(String words) {
  if(words == null) return '';
  var arrOfWord = words.trim().split(' ');
  switch (arrOfWord.length) {
    case 0:
      return '?';
    case 1:
      return arrOfWord[0][0].toUpperCase();
    default:
      return arrOfWord[0][0].toUpperCase() + arrOfWord[1][0].toUpperCase();
  }
}